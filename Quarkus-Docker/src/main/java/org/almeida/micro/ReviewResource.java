package org.almeida.micro;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.transaction.Transactional;
import java.util.List;

@Path("/reviews")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ReviewResource {

    @GET
    public List<Review> getAll() {
        return Review.listAll();
    }

    @GET
    @Path("/{id}")
    public Review getById(@PathParam("id") Long id) {
        return Review.findById(id);
    }

    @POST
    @Transactional
    public void create(Review review) {
        review.persist();
    }
} 