package org.almeida.micro;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.transaction.Transactional;
import java.util.List;

@Path("/movies")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class MovieResource {

    @GET
    public List<Movie> getAll() {
        return Movie.listAll();
    }

    @GET
    @Path("/{id}")
    public Movie getById(@PathParam("id") Long id) {
        return Movie.findById(id);
    }

    @POST
    @Transactional
    public void create(Movie movie) {
        movie.persist();
    }

    @GET
    @Path("/{id}/reviews")
    public List<Review> getReviews(@PathParam("id") Long id) {
        Movie movie = Movie.findById(id);
        if (movie == null || movie.reviews == null) return List.of();
        return movie.reviews.stream().toList();
    }
} 