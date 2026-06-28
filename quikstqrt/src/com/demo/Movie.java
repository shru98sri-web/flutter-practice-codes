package com.demo;

public class Movie {

    private String movieName;
    private String genre;
    private int year;
    private int duration;
    private String actor;
    public Movie() {
        super();
        // TODO Auto-generated constructor stub
    }
    public Movie(String movieName, String genre, int year, int duration, String actor) {
        super();
        this.movieName = movieName;
        this.genre = genre;
        this.year = year;
        this.duration = duration;
        this.actor = actor;
    }
    public String getMovieName() {
        return movieName;
    }
    public void setMovieName(String movieName) {
        this.movieName = movieName;
    }
    public String getGenre() {
        return genre;
    }
    public void setGenre(String genre) {
        this.genre = genre;
    }
    public int getYear() {
        return year;
    }
    public void setYear(int year) {
        this.year = year;
    }
    public int getDuration() {
        return duration;
    }
    public void setDuration(int duration) {
        this.duration = duration;
    }
    public String getActor() {
        return actor;
    }
    public void setActor(String actor) {
        this.actor = actor;
    }
    @Override
    public String toString() {
        return "MovieList [movieName=" + movieName + ", genre=" + genre + ", year=" + year + ", duration=" + duration
                + ", actor=" + actor + "]";
    }




}
