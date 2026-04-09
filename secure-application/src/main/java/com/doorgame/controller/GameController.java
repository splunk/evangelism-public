package com.doorgame.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.Random;

@Controller
public class GameController {

    private final Random random = new Random();

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("stage", "pick");
        return "game";
    }

    @PostMapping("/pick")
    public String pick(@RequestParam int door, Model model) {
        int prizeDoor = random.nextInt(3) + 1;

        // Find a door to reveal (not the picked door, not the prize door)
        int revealDoor;
        do {
            revealDoor = random.nextInt(3) + 1;
        } while (revealDoor == door || revealDoor == prizeDoor);

        model.addAttribute("stage", "switch");
        model.addAttribute("picked", door);
        model.addAttribute("revealed", revealDoor);
        model.addAttribute("prizeDoor", prizeDoor);
        return "game";
    }

    @PostMapping("/decide")
    public String decide(
            @RequestParam int picked,
            @RequestParam int prizeDoor,
            @RequestParam int revealed,
            @RequestParam boolean switchDoor,
            Model model) {

        int finalDoor;
        if (switchDoor) {
            // Switch to the door that isn't picked and isn't revealed
            finalDoor = 6 - picked - revealed; // doors 1+2+3=6
        } else {
            finalDoor = picked;
        }

        boolean won = (finalDoor == prizeDoor);
        model.addAttribute("stage", "result");
        model.addAttribute("finalDoor", finalDoor);
        model.addAttribute("prizeDoor", prizeDoor);
        model.addAttribute("won", won);
        model.addAttribute("switched", switchDoor);
        return "game";
    }
}
