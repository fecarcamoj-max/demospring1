package com.proyectoduoc.demo2;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import com.proyectoduoc.demo2.model.Car;

@RestController
public class HolaMundoController {

    @GetMapping("/")
    public String getMethodName() {
        return "Hola Mundo 00:32:30 27 06 2026 !! Cierre de act práctica pipeline";
    }

    @GetMapping("/getCar")
    public Car getCar() {
        return new Car("camioneta",  123);
    }
    

    @GetMapping("/sendMessage")
    public String getMethodName2(@RequestParam String param) {
        return param;
    }

    @PostMapping("/setValue")
    public String postMethodName1(@RequestBody String entity) {
        return entity;
    }
    
    
    

}
