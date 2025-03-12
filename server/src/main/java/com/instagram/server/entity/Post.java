package com.instagram.server.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.util.List;

@Entity
@Data
@Table(name = "posts")
public class Post {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long postId;

    @Column(name = "image_url")
    private String contentUrl;

    @Column(name = "caption")
    private String caption;

    @Column(name = "created_at")
    private String createdAt;

    @ManyToOne
    @JoinColumn(name = "userId", insertable = false, updatable = false)
    private User user;

    /*Note*/
    @OneToMany(mappedBy = "post")
    private List<Comment> comments;

    @OneToMany(mappedBy = "post")
    private List<Like> likes;

}
