import React from 'react';
import client from './client';
import { ApolloProvider } from "@apollo/client";
import WormTimeSlots from './AstronautTimeSlots';

const WormsInSpace = () => {
    return <ApolloProvider client={client}><WormTimeSlots /></ApolloProvider>
}

export default WormsInSpace;