package org.almeida.micro;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.transaction.Transactional;
import java.util.List;

@Path("/critics")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class CriticResource {

    @GET
    public List<Critic> getAll() {
        return Critic.listAll();
    }

    @GET
    @Path("/{id}")
    public Critic getById(@PathParam("id") Long id) {
        return Critic.findById(id);
    }

    @POST
    @Transactional
    public void create(Critic critic) {
        critic.persist();
    }

    @GET
    @Path("/{id}/reviews")
    public List<Review> getReviews(@PathParam("id") Long id) {
        Critic critic = Critic.findById(id);
        if (critic == null || critic.reviews == null) return List.of();
        return critic.reviews.stream().toList();
    }
} 