package org.almeida.micro;

import io.quarkus.hibernate.orm.panache.PanacheEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.Column;
import jakarta.persistence.OneToMany;
import java.util.Set;

@Entity
@Table(name = "movies")
public class Movie extends PanacheEntity {
    @Column(nullable = false, unique = true)
    public String title;

    @OneToMany(mappedBy = "movie")
    public Set<Review> reviews;
} 