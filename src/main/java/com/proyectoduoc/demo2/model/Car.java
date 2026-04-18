package com.proyectoduoc.demo2.model;

public class Car {

    public String type;
    public Integer size_engine;
    public String color;
    public String brand;

    public Car(String type, Integer size_engine){
        this.type = type;
        this.size_engine = size_engine;
    }

    public String getType(){
        return this.type;
    }

    public Integer getSize_engine(){
        return this.size_engine;
    }
}
