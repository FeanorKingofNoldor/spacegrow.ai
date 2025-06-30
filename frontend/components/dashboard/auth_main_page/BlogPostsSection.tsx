// components/dashboard/BlogPostsSection.tsx
'use client';

export function BlogPostsSection() {
  const blogPosts = [
    { title: "New Firmware v2.1.0 Released", date: "2 days ago", tag: "Update" },
    { title: "Optimizing LED Schedules for Winter", date: "1 week ago", tag: "Guide" },
    { title: "Community Showcase: Hydroponic Lettuce", date: "2 weeks ago", tag: "Community" }
  ];

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-4">Latest Blog Posts</h2>
      <div className="space-y-3">
        {blogPosts.map((post, index) => (
          <div key={index} className="flex items-center justify-between p-3 bg-space-secondary rounded-lg hover:bg-space-glass transition-colors cursor-pointer">
            <div>
              <h3 className="font-medium text-cosmic-text text-sm">{post.title}</h3>
              <p className="text-xs text-cosmic-text-muted">{post.date}</p>
            </div>
            <span className="px-2 py-1 bg-stellar-accent/10 text-stellar-accent text-xs rounded-full">
              {post.tag}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}