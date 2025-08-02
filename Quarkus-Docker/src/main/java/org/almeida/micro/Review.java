package org.almeida.micro;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;

@Entity
@Table(name = "reviews")
public class Review extends PanacheEntity {
    @ManyToOne
    @JoinColumn(name = "movie_id", nullable = false)
    public Movie movie;

    @ManyToOne
    @JoinColumn(name = "critic_id", nullable = false)
    public Critic critic;

    @Column(nullable = false)
    public int rating;

    @Column(length = 1000)
    public String comment;
} 