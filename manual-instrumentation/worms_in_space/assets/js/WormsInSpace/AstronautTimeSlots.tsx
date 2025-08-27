import React, { useState, useCallback } from "react";
import { gql, useMutation, useQuery } from "@apollo/client";
import { SplunkRum } from '@splunk/otel-web';

interface TimeSlot {
    id: number | string;
    startTime: string;
}

interface SpaceWalkResult {
    startTime: string;
}

interface ScheduledWalk {
    id: string;
    startTime: string;
    walkType: string;
    slotId?: string;
    status: string;
    scheduledAt: string;
}

const worm_TIME_SLOTS = gql`
{
    wormTimeSlots {
        id
        startTime
    }
}
`;

const SCHEDULED_WALKS_QUERY = gql`
query {
    scheduledWalks {
        id
        startTime
        walkType
        slotId
        status
        scheduledAt
    }
}
`;

const worm_SPACE_WALK = gql`
mutation($id: ID, $alternateTime: String){
    wormSpaceWalk(id: $id, alternateTime: $alternateTime) {
        id
        startTime
        walkType
        slotId
        status
        scheduledAt
    }
}
`;

const DELETE_SCHEDULED_WALK = gql`
mutation($id: ID!){
    deleteScheduledWalk(id: $id) {
        id
        startTime
        status
    }
}
`;

type ViewState = 'selection' | 'success';

const WormTimeSlots = () => {
    const { data, loading, error } = useQuery(worm_TIME_SLOTS);
    const { data: scheduledWalksData, loading: walksLoading, error: walksError, refetch: refetchScheduledWalks } = useQuery(SCHEDULED_WALKS_QUERY);
    const [selectedTimeSlotId, setSelectedTimeSlotId] = useState<string>('');
    const [alternateTime, setAlternateTime] = useState('');
    const [viewState, setViewState] = useState<ViewState>('selection');
    const [spaceWalkResult, setSpaceWalkResult] = useState<SpaceWalkResult | null>(null);
    const [submitError, setSubmitError] = useState<string>('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    const [wormSpaceWalk] = useMutation(worm_SPACE_WALK);
    const [deleteScheduledWalk] = useMutation(DELETE_SCHEDULED_WALK);

    // Get scheduled walks from query data
    const scheduledWalks: ScheduledWalk[] = scheduledWalksData?.scheduledWalks || [];

    const handleTimeSlotChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSelectedTimeSlotId(event.target.value);
        setAlternateTime(''); // Clear alternate time if a predefined slot is selected
        setSubmitError('');
    };

    const handleAlternateTimeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setAlternateTime(event.target.value);
        setSelectedTimeSlotId(''); // Clear selected slot if alternate time is entered
        setSubmitError('');
    };

    const isValidDateTime = (dateTimeString: string): boolean => {
        if (!dateTimeString) return false;
        const date = new Date(dateTimeString);
        return date instanceof Date && !isNaN(date.getTime());
    };

    const convertToISOString = (datetimeLocal: string): string => {
        if (!datetimeLocal) return '';
        // datetime-local format is YYYY-MM-DDTHH:MM, convert to ISO 8601
        const date = new Date(datetimeLocal);
        return date.toISOString();
    };

    const formatDisplayDate = (isoString: string): string => {
        const date = new Date(isoString);
        return date.toLocaleString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            timeZoneName: 'short'
        });
    };

    const handleDeleteScheduledWalk = async (walkId: string) => {
        // Create custom span for space walk deletion operation
        const span = SplunkRum.provider.getTracer('worms-in-space-frontend').startSpan('delete_scheduled_walk');
        span.setAttributes({
            'spacewalk.delete.walk_id': walkId
        });
        
        try {
            await deleteScheduledWalk({ 
                variables: { id: walkId }
            });
            // Refetch the scheduled walks to update the UI
            refetchScheduledWalks();
            
            span.setAttributes({
                'spacewalk.delete.success': true
            });
            span.setStatus({ code: 1 }); // OK status
        } catch (error) {
            span.recordException(error as Error);
            span.setStatus({ code: 2, message: (error as Error).message });
            console.error('Error deleting scheduled walk:', error);
        } finally {
            span.end();
        }
    };

    const canSubmit = selectedTimeSlotId !== '' || alternateTime !== '';

    const handleSubmit = async (event: React.FormEvent) => {
        event.preventDefault();
        setSubmitError('');
        setIsSubmitting(true);

        // Create custom span for space walk scheduling operation
        const span = SplunkRum.provider.getTracer('worms-in-space-frontend').startSpan('schedule_space_walk');
        
        try {
            let variables: { id?: string; alternateTime?: string } = {};

            if (selectedTimeSlotId) {
                variables.id = selectedTimeSlotId;
                span.setAttributes({
                    'spacewalk.slot_type': 'predefined',
                    'spacewalk.slot_id': selectedTimeSlotId
                });
            } else if (alternateTime) {
                const isoString = convertToISOString(alternateTime);
                if (!isValidDateTime(isoString)) {
                    span.recordException(new Error('Invalid date and time selected'));
                    span.setStatus({ code: 2, message: 'Invalid date and time' });
                    setSubmitError('Please select a valid date and time');
                    setIsSubmitting(false);
                    return;
                }
                variables.alternateTime = isoString;
                span.setAttributes({
                    'spacewalk.slot_type': 'custom',
                    'spacewalk.custom_time': isoString
                });
            }

            const result = await wormSpaceWalk({ variables });
            
            if (result.data?.wormSpaceWalk) {
                span.setAttributes({
                    'spacewalk.scheduled': true,
                    'spacewalk.result_time': result.data.wormSpaceWalk.startTime
                });
                
                setSpaceWalkResult({ startTime: result.data.wormSpaceWalk.startTime });
                
                // Refetch scheduled walks to update the sidebar
                refetchScheduledWalks();
                setViewState('success');
                
                span.setStatus({ code: 1 }); // OK status
            }
        } catch (err: any) {
            span.recordException(err);
            span.setStatus({ code: 2, message: err.message });
            setSubmitError(err.message || 'An error occurred while scheduling your space walk');
        } finally {
            span.end();
            setIsSubmitting(false);
        }
    };

    const handleScheduleAnother = () => {
        setViewState('selection');
        setSelectedTimeSlotId('');
        setAlternateTime('');
        setSpaceWalkResult(null);
        setSubmitError('');
    };

    if (loading) return <div className="loading">Loading available time slots...</div>;
    if (error) return <div className="error">Error loading time slots: {error.message}</div>;

    if (viewState === 'success') {
        return (
            <div className="app_container">
                <div className="scheduler_layout">
                    <div className="main_content">
                        <div className="worm_time_slots">
                            <div className="success_page">
                                <h1 className="success_header">🚀 Space Walk Scheduled Successfully!</h1>
                                <div className="success_details">
                                    <h3>Your space walk is confirmed for:</h3>
                                    <p className="scheduled_time">{formatDisplayDate(spaceWalkResult?.startTime || '')}</p>
                                    <p>Safe travels, astronaut! 👨‍🚀</p>
                                </div>
                                <button 
                                    className="schedule_another_button"
                                    onClick={handleScheduleAnother}
                                    type="button"
                                >
                                    Schedule Another Space Walk
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Sidebar also shown on success page */}
                    <div className="sidebar">
                        <div className="scheduled_walks_panel">
                            <h3 className="sidebar_header">
                                🚀 Scheduled Spacewalks
                                {scheduledWalks.length > 0 && (
                                    <span className="walks_count">({scheduledWalks.length})</span>
                                )}
                            </h3>
                            
                            {scheduledWalks.length === 0 ? (
                                <div className="no_scheduled_walks">
                                    <p>No spacewalks scheduled yet.</p>
                                    <p>Schedule your first spacewalk to see it here!</p>
                                </div>
                            ) : (
                                <div className="scheduled_walks_list">
                                    {scheduledWalks.map((walk) => (
                                        <div key={walk.id} className="scheduled_walk_item">
                                            <div className="walk_header">
                                                <span className={`walk_type_badge ${walk.walkType}`}>
                                                    {walk.walkType === 'predefined' ? '⏰' : '📅'}
                                                    {walk.walkType === 'predefined' ? 'Preset' : 'Custom'}
                                                </span>
                                                <button
                                                    className="delete_walk_button"
                                                    onClick={() => handleDeleteScheduledWalk(walk.id)}
                                                    title="Cancel spacewalk"
                                                >
                                                    ✕
                                                </button>
                                            </div>
                                            <div className="walk_time">
                                                {formatDisplayDate(walk.startTime)}
                                            </div>
                                            <div className="walk_scheduled">
                                                Scheduled: {formatDisplayDate(walk.scheduledAt)}
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="app_container">
            <div className="scheduler_layout">
                <div className="main_content">
                    <div className="worm_time_slots">
                        <h1 className="worm_time_slots_header">Space Walk Scheduler</h1>
                        <h3>Select a start time for your spacewalk</h3>
                        
                        <form onSubmit={handleSubmit}>
                            {/* Predefined Time Slots */}
                            <div className="predefined_slots">
                                <h4>Available Time Slots:</h4>
                                {data?.wormTimeSlots ? data.wormTimeSlots.map((timeslot: TimeSlot) => (
                                    <div key={timeslot.id} className="worm_time_slot_option">
                                        <label>
                                            <input
                                                type="radio"
                                                value={timeslot.id}
                                                name="time_slot"
                                                checked={selectedTimeSlotId === timeslot.id.toString()}
                                                onChange={handleTimeSlotChange}
                                            />
                                            {formatDisplayDate(timeslot.startTime)}
                                        </label>
                                    </div>
                                )) : <p>No predefined time slots available</p>}
                            </div>

                            {/* Alternate Time Input */}
                            <div className="alternate_time_section">
                                <h4>Or choose your own time:</h4>
                                <div className="datetime_picker_container">
                                    <input
                                        type="datetime-local"
                                        value={alternateTime}
                                        onChange={handleAlternateTimeChange}
                                        className="datetime_picker"
                                    />
                                </div>
                                <small className="time_format_help">
                                    Select your preferred date and time for the space walk
                                </small>
                            </div>

                            {/* Error Message */}
                            {submitError && (
                                <div className="error_message">
                                    {submitError}
                                </div>
                            )}

                            {/* Submit Button */}
                            <div className="submit_section">
                                <button 
                                    type="submit" 
                                    className="submit_button"
                                    disabled={!canSubmit || isSubmitting}
                                >
                                    {isSubmitting ? 'Scheduling...' : 'Schedule Space Walk'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                {/* Side Panel for Scheduled Walks */}
                <div className="sidebar">
                    <div className="scheduled_walks_panel">
                        <h3 className="sidebar_header">
                            🚀 Scheduled Spacewalks
                            {scheduledWalks.length > 0 && (
                                <span className="walks_count">({scheduledWalks.length})</span>
                            )}
                        </h3>
                        
                        {scheduledWalks.length === 0 ? (
                            <div className="no_scheduled_walks">
                                <p>No spacewalks scheduled yet.</p>
                                <p>Schedule your first spacewalk to see it here!</p>
                            </div>
                        ) : (
                            <div className="scheduled_walks_list">
                                {scheduledWalks.map((walk) => (
                                    <div key={walk.id} className="scheduled_walk_item">
                                        <div className="walk_header">
                                            <span className={`walk_type_badge ${walk.walkType}`}>
                                                {walk.walkType === 'predefined' ? '⏰' : '📅'}
                                                {walk.walkType === 'predefined' ? 'Preset' : 'Custom'}
                                            </span>
                                            <button
                                                className="delete_walk_button"
                                                onClick={() => handleDeleteScheduledWalk(walk.id)}
                                                title="Cancel spacewalk"
                                            >
                                                ✕
                                            </button>
                                        </div>
                                        <div className="walk_time">
                                            {formatDisplayDate(walk.startTime)}
                                        </div>
                                        <div className="walk_scheduled">
                                            Scheduled: {formatDisplayDate(walk.scheduledAt)}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default WormTimeSlots;