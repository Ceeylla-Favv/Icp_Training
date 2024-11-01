import Nat "mo:base/Nat"; 
import Time "mo:base/Time";
import Array "mo:base/Array";
import Text "mo:base/Text";

actor {
    // Persistent storage
    stable var users: [UserProfile] = [];
    stable var posts: [Post] = [];

    // Data structures for user profiles, posts, and comments
    public type UserProfile = {
        id: Text;
        username: Text;
        bio: Text;
        following: [Text];
        followers: [Text];
    };

    public type Post = {
        id: Text;
        authorId: Text;
        content: Text;
        timestamp: Int;
        likes: [Text];
        comments: [Comment];
    };

    public type Comment = {
        authorId: Text;
        content: Text;
        timestamp: Int;
    };

    // Utility functions
   // Utility functions
    public func getUserById(id: Text): async ?UserProfile {
        return Array.find<UserProfile>(users, func(user: UserProfile) {
             return user.id == id;
         });
    };

    public func getPostById(id: Text): async ?Post {
        return Array.find<Post>(posts, func(post: Post) {
            return post.id == id;
        });
    };


    // Functions for managing user profiles
    // public func createUserProfile(id: Text, username: Text, bio: Text): async Bool {
    //     if (await getUserById(id) == null) {
    //         let newUser: UserProfile = { id; username; bio; following = []; followers = [] };
    //         users := Array.append<UserProfile>(users, [newUser]);
    //         return true;
    //     };
    //     return false;
    // };

    public func createUserProfile(id: Text, username: Text, bio: Text): async Bool {
    let userOpt = await getUserById(id); // Await the async call
    if (userOpt == null) {
        let newUser: UserProfile = { id; username; bio; following = []; followers = [] };
        users := Array.append<UserProfile>(users, [newUser]);
        return true;
    };
    return false;
};



    public func followUser(followerId: Text, followeeId: Text): async Bool {
        let followerOpt = await getUserById(followerId);
        let followeeOpt = await getUserById(followeeId);
        
        switch (followerOpt, followeeOpt) {
            case (?follower, ?followee) {
                // Check if follower is already following the followee
                if (Array.find<Text>(follower.following, func(followingId: Text) { followingId == followeeId }) == null) {
                    // Create updated copies of follower and followee with updated following/followers lists
                    let updatedFollower: UserProfile = {
                        id = follower.id;
                        username = follower.username;
                        bio = follower.bio;
                        following = Array.append<Text>(follower.following, [followeeId]);
                        followers = follower.followers;
                    };
                    let updatedFollowee: UserProfile = {
                        id = followee.id;
                        username = followee.username;
                        bio = followee.bio;
                        following = followee.following;
                        followers = Array.append<Text>(followee.followers, [followerId]);
                    };
                    
                    // Update the persistent storage with the new versions
                    users := Array.map<UserProfile, UserProfile>(users, func(user: UserProfile): UserProfile {
                        if (user.id == followerId) {
                            return updatedFollower;
                        };
                        if (user.id == followeeId) {
                            return updatedFollowee;
                        };
                        return user;
                    });

                    return true; // Successfully followed
                };
                return false; // Already following
            };
            case (null, _) { return false }; // Follower not found
            case (_, null) { return false }; // Followee not found
        };
    };

    // Functions for managing posts and interactions

    public func createPost(authorId: Text, content: Text): async Bool {
        let postId = Text.concat("post-", Nat.toText(posts.size()));
        let newPost: Post = {
            id = postId;
            authorId = authorId; // Explicit assignment
            content = content; // Explicit assignment
            timestamp = Time.now();
            likes = [];
            comments = [];
        };
        posts := Array.append<Post>(posts, [newPost]);
        return true;
    };

  public func likePost(userId: Text, postId: Text): async Bool {
    switch (await getPostById(postId)) {
        case (?post) {
            // Check if the user has already liked the post
            let alreadyLiked = Array.find<Text>(post.likes, func(likeId: Text) { likeId == userId }) != null;
            if (alreadyLiked) {
                return false; // Already liked
            };

            // If not liked, proceed to like the post
            let updatedPost: Post = {
                id = post.id;
                authorId = post.authorId;
                content = post.content;
                timestamp = post.timestamp;
                likes = Array.append<Text>(post.likes, [userId]); // Add userId to likes
                comments = post.comments;
            };

            // Corrected Array.map usage
            posts := Array.map<Post, Post>(posts, func(p: Post) {
                if (p.id == postId) {
                    return updatedPost; // Return updated post
                };
                return p; // Return original post
            });
            return true; // Successfully liked the post
        };
        case null {
            return false; // Post not found
        };
    };
  };



    public func addComment(postId: Text, authorId: Text, content: Text): async Bool {
    switch (await getPostById(postId)) {
        case (?post) {
            let comment: Comment = {
                authorId = authorId; // Explicit assignment
                content = content; // Explicit assignment
                timestamp = Time.now();
            };
            // Update the comments array by creating a new post with updated comments
            let updatedPost: Post = {
                id = post.id;
                authorId = post.authorId;
                content = post.content;
                timestamp = post.timestamp;
                likes = post.likes;
                comments = Array.append<Comment>(post.comments, [comment]);
            };

            posts := Array.map<Post, Post>(posts, func(p: Post) {
                if (p.id == postId) {
                    return updatedPost;
                };
                return p;
            });
            return true; // Successfully added the comment
        };
        case null { return false }; // Post not found
    };
  };

    // Security with Basic Access Checks
    public func deletePost(authorId: Text, postId: Text): async Bool {
        switch (await getPostById(postId)) {
            case (?post) {
                if (post.authorId == authorId) {
                    posts := Array.filter<Post>(posts, func (p: Post) { p.id != postId });
                    return true; // Successfully deleted the post
                };
                return false; // Not authorized to delete
            };
            case null { return false; } // Post not found
        };
    };
};
