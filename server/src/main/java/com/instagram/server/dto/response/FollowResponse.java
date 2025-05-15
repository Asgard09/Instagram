package com.instagram.server.dto.response;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FollowResponse {
    private Long userId;
    private String username;
    private String profilePicture;
    private boolean isFollowing;
    private int followersCount;
    private int followingCount;
    private int postsCount;
}
