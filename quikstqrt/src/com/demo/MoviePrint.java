package com.demo;

public class MoviePrint {

    public static void main(String[] args) {
        // TODO Auto-generated method stub

        Movie inter = new Movie();
        inter.setActor("sita");
        inter.setDuration(1);
        inter.setGenre("drama");
        inter.setMovieName("abc1");
        inter.setYear(2013);

        System.out.println(inter.toString());


        Movie movieList2 = new Movie("abc", "comedy", 2012, 2, "ram");
        System.out.println(movieList2.getMovieName());
        System.out.println(movieList2.getGenre());
        System.out.println(movieList2.getYear());
        System.out.println(movieList2.getDuration());
        System.out.println(movieList2.getActor());

        Movie movieList3 = new Movie("abc3","fantasy",2014,1,"lakshman");
        System.out.println(movieList3.toString());

    }

}
