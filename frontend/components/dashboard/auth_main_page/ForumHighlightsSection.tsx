// components/dashboard/ForumHighlightsSection.tsx
'use client';

export function ForumHighlightsSection() {
  const forumTopics = [
    { title: "Best nutrients for hydroponic tomatoes?", replies: 12, category: "Nutrition" },
    { title: "DIY CO2 generator setup", replies: 8, category: "DIY" },
    { title: "Troubleshooting pH sensor drift", replies: 15, category: "Tech Support" }
  ];

  return (
    <div className="bg-space-glass backdrop-blur-md border border-space-border rounded-xl p-6">
      <h2 className="text-xl font-semibold text-cosmic-text mb-4">Forum Highlights</h2>
      <div className="space-y-3">
        {forumTopics.map((topic, index) => (
          <div key={index} className="flex items-center justify-between p-3 bg-space-secondary rounded-lg hover:bg-space-glass transition-colors cursor-pointer">
            <div>
              <h3 className="font-medium text-cosmic-text text-sm">{topic.title}</h3>
              <div className="flex items-center space-x-2 text-xs text-cosmic-text-muted">
                <span>{topic.replies} replies</span>
                <span>•</span>
                <span>{topic.category}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}