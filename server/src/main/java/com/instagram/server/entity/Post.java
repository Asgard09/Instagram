package com.instagram.server.entity;

import com.fasterxml.jackson.annotation.JsonIdentityInfo;
import com.fasterxml.jackson.annotation.JsonIdentityReference;
import com.fasterxml.jackson.annotation.ObjectIdGenerators;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/*Note
* Doesn't use @Data of lombok if you have circle relationships
* Because it will auto generate toString() when log or debug
* If posts stores likes and likes stores posts it will create recursive of toString()*/
@Entity
@Getter
@Setter
@Table(name = "posts")
@NoArgsConstructor
@AllArgsConstructor
@JsonIdentityInfo(
        generator = ObjectIdGenerators.PropertyGenerator.class,
        property = "postId"
)
public class Post {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long postId;

    @Column(name = "content")
    private String content;

    @Column(name = "caption")
    private String caption;

    @Column(name = "created_at")
    private Date createdAt;

    @ElementCollection
    @CollectionTable(name = "post_images", joinColumns = @JoinColumn(name = "post_id"))
    @Column(name = "image_url")
    private List<String> imageUrls = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "post_tagged_people", joinColumns = @JoinColumn(name = "post_id"))
    @Column(name = "username")
    private List<String> taggedPeople = new ArrayList<>();

    @ManyToOne
    @JoinColumn(name = "userId")
    @JsonIdentityInfo(generator = ObjectIdGenerators.PropertyGenerator.class, property = "userId")
    @JsonIdentityReference()
    private User user;

    /*Note*/
    @OneToMany(mappedBy = "post")
    private List<Comment> comments;

    @OneToMany(mappedBy = "post")
    private List<Like> likes;

    @OneToMany(mappedBy = "post")
    private List<PostSave> postSaves;

}
