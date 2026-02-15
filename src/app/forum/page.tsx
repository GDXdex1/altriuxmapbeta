'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Home, MessageSquare, Crown, Shield, Send, ThumbsUp } from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import type { ForumPost, ForumCategory } from '@/types/game';

export default function ForumPage(): JSX.Element {
  const [newPost, setNewPost] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('general');

  // Mock moderators - will be managed via blockchain
  const moderators = ['0x742d...8f3c']; // Your wallet address as initial moderator

  // Mock current user
  const currentUser = {
    wallet: '0x9a3e...2b1c',
    title: undefined // or NFT title if player has one
  };

  // Forum categories
  const categories: ForumCategory[] = [
    { id: 'general', name: 'General', description: 'General discussions', icon: '💬', postCount: 24 },
    { id: 'trading', name: 'Trading', description: 'Buy, sell, and trade', icon: '🤝', postCount: 18 },
    { id: 'strategy', name: 'Strategy', description: 'Game strategies and tips', icon: '🎯', postCount: 31 },
    { id: 'alliances', name: 'Alliances', description: 'Form alliances and coalitions', icon: '🤝', postCount: 12 },
    { id: 'bugs', name: 'Bugs & Reports', description: 'Report issues', icon: '🐛', postCount: 7 }
  ];

  // Mock forum posts
  const mockPosts: ForumPost[] = [
    {
      id: 'p1',
      author: 'Explorer_Alpha',
      authorWallet: '0x742d...8f3c',
      authorTitle: 'Resource Baron',
      content: 'Just discovered a massive gold deposit in Duchy #15230! Anyone interested in forming a mining coalition?',
      timestamp: new Date('2026-01-10T10:30:00'),
      likes: 12,
      replies: [
        {
          id: 'r1',
          author: 'Trader_Beta',
          authorWallet: '0x8b2f...3a4d',
          authorTitle: undefined,
          content: 'I\'m interested! I have advanced mining tools we could use.',
          timestamp: new Date('2026-01-10T11:15:00')
        },
        {
          id: 'r2',
          author: 'Miner_Gamma',
          authorWallet: '0x3c1e...9f7a',
          authorTitle: 'Master Blacksmith',
          content: 'Count me in. I can process the ore efficiently.',
          timestamp: new Date('2026-01-10T12:00:00')
        }
      ]
    },
    {
      id: 'p2',
      author: 'Strategist_Delta',
      authorWallet: '0x5d4a...8e2b',
      authorTitle: 'Scholar of Mathematics',
      content: 'PSA: The optimal trade route between America and Europe continents uses these specific duchies...',
      timestamp: new Date('2026-01-10T09:00:00'),
      likes: 28,
      replies: []
    },
    {
      id: 'p3',
      author: 'Plebeian_User',
      authorWallet: '0x1f2e...4c5d',
      authorTitle: undefined,
      content: 'New player here! Looking for tips on getting started. Any advice?',
      timestamp: new Date('2026-01-10T08:15:00'),
      likes: 8,
      replies: [
        {
          id: 'r3',
          author: 'Explorer_Alpha',
          authorWallet: '0x742d...8f3c',
          authorTitle: 'Resource Baron',
          content: 'Welcome! Start by claiming duchies near resources you need. Focus on building up your science tree early.',
          timestamp: new Date('2026-01-10T08:45:00')
        }
      ]
    }
  ];

  const handlePostSubmit = (): void => {
    if (newPost.trim()) {
      // Will be implemented with blockchain
      console.log('Posting:', newPost);
      setNewPost('');
    }
  };

  const isModerator = moderators.includes(currentUser.wallet);

  return (
    <main className="min-h-screen bg-gradient-to-br from-purple-900 via-pink-900 to-slate-900 p-4 md:p-6">
      {/* Header */}
      <div className="max-w-6xl mx-auto mb-6">
        <div className="flex items-center justify-between mb-4">
          <Link href="/">
            <Button variant="outline" size="sm" className="gap-2">
              <Home className="w-4 h-4" />
              Home
            </Button>
          </Link>
          <h1 className="text-3xl md:text-4xl font-bold text-white">Forum</h1>
          <div className="w-20" />
        </div>

        {/* Moderator Badge */}
        {isModerator && (
          <div className="mb-4 p-3 bg-yellow-500/20 border border-yellow-500/50 rounded-lg">
            <div className="flex items-center gap-2">
              <Shield className="w-5 h-5 text-yellow-300" />
              <p className="text-yellow-200 font-semibold">Moderator Panel</p>
            </div>
          </div>
        )}

        {/* Categories Grid */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-6">
          {categories.map((category: ForumCategory) => (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className={`p-4 rounded-lg border-2 transition-all ${
                selectedCategory === category.id
                  ? 'bg-purple-600 border-purple-400'
                  : 'bg-white/10 border-white/20 hover:border-purple-400'
              }`}
            >
              <div className="text-3xl mb-2">{category.icon}</div>
              <h3 className="text-white font-semibold text-sm mb-1">{category.name}</h3>
              <p className="text-purple-300 text-xs">{category.postCount} posts</p>
            </button>
          ))}
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-6xl mx-auto">
        <Tabs defaultValue="posts" className="w-full">
          <TabsList className="grid w-full grid-cols-2 bg-white/10 backdrop-blur-md border-white/20">
            <TabsTrigger value="posts" className="data-[state=active]:bg-purple-600">
              <MessageSquare className="w-4 h-4 mr-2" />
              Posts
            </TabsTrigger>
            <TabsTrigger value="create" className="data-[state=active]:bg-purple-600">
              <Send className="w-4 h-4 mr-2" />
              Create Post
            </TabsTrigger>
          </TabsList>

          {/* Posts Tab */}
          <TabsContent value="posts" className="mt-4">
            <div className="space-y-4">
              {mockPosts.map((post: ForumPost) => (
                <Card key={post.id} className="bg-white/10 backdrop-blur-md border-white/20 p-6">
                  {/* Post Header */}
                  <div className="flex items-start gap-4 mb-4">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 flex items-center justify-center flex-shrink-0">
                      <span className="text-white font-bold text-lg">
                        {post.author[0]}
                      </span>
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 flex-wrap mb-1">
                        <h3 className="text-white font-bold">{post.author}</h3>
                        {post.authorTitle ? (
                          <Badge className="bg-yellow-500/20 text-yellow-300 border-yellow-500/30 gap-1">
                            <Crown className="w-3 h-3" />
                            {post.authorTitle}
                          </Badge>
                        ) : (
                          <Badge className="bg-gray-500/20 text-gray-300 border-gray-500/30">
                            Plebeian
                          </Badge>
                        )}
                        {moderators.includes(post.authorWallet) && (
                          <Badge className="bg-yellow-600/20 text-yellow-400 border-yellow-600/30 gap-1">
                            <Shield className="w-3 h-3" />
                            Mod
                          </Badge>
                        )}
                      </div>
                      <p className="text-purple-300 text-xs">
                        {post.authorWallet} • {post.timestamp.toLocaleString()}
                      </p>
                    </div>
                  </div>

                  {/* Post Content */}
                  <p className="text-white mb-4">{post.content}</p>

                  {/* Post Actions */}
                  <div className="flex items-center gap-4">
                    <Button variant="ghost" size="sm" className="gap-2 text-purple-300 hover:text-purple-100">
                      <ThumbsUp className="w-4 h-4" />
                      {post.likes}
                    </Button>
                    <span className="text-purple-300 text-sm">
                      {post.replies.length} {post.replies.length === 1 ? 'reply' : 'replies'}
                    </span>
                  </div>

                  {/* Replies */}
                  {post.replies.length > 0 && (
                    <div className="mt-4 pl-4 border-l-2 border-purple-500/30 space-y-3">
                      {post.replies.map((reply) => (
                        <div key={reply.id} className="bg-black/20 rounded-lg p-4">
                          <div className="flex items-start gap-3 mb-2">
                            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center flex-shrink-0">
                              <span className="text-white font-bold text-sm">
                                {reply.author[0]}
                              </span>
                            </div>
                            <div className="flex-1">
                              <div className="flex items-center gap-2 flex-wrap mb-1">
                                <h4 className="text-white font-semibold text-sm">{reply.author}</h4>
                                {reply.authorTitle ? (
                                  <Badge className="bg-yellow-500/20 text-yellow-300 border-yellow-500/30 gap-1 text-xs">
                                    <Crown className="w-2 h-2" />
                                    {reply.authorTitle}
                                  </Badge>
                                ) : (
                                  <Badge className="bg-gray-500/20 text-gray-300 border-gray-500/30 text-xs">
                                    Plebeian
                                  </Badge>
                                )}
                              </div>
                              <p className="text-purple-400 text-xs mb-2">{reply.timestamp.toLocaleString()}</p>
                              <p className="text-white text-sm">{reply.content}</p>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </Card>
              ))}
            </div>
          </TabsContent>

          {/* Create Post Tab */}
          <TabsContent value="create" className="mt-4">
            <Card className="bg-white/10 backdrop-blur-md border-white/20 p-6">
              <h3 className="text-xl font-bold text-white mb-4">Create New Post</h3>
              
              <div className="mb-4">
                <label className="text-purple-200 text-sm mb-2 block">
                  Category: {categories.find((c) => c.id === selectedCategory)?.name}
                </label>
              </div>

              <div className="mb-4">
                <Textarea
                  value={newPost}
                  onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setNewPost(e.target.value)}
                  placeholder="Share your thoughts with the community..."
                  className="bg-black/30 text-white border-white/20 min-h-[150px]"
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="text-purple-300 text-sm">
                  {currentUser.title ? (
                    <span>Posting as <strong>{currentUser.title}</strong></span>
                  ) : (
                    <span>Posting as <strong>Plebeian</strong></span>
                  )}
                </div>
                <Button 
                  onClick={handlePostSubmit}
                  disabled={!newPost.trim()}
                  className="bg-purple-600 hover:bg-purple-700"
                >
                  <Send className="w-4 h-4 mr-2" />
                  Post
                </Button>
              </div>

              <div className="mt-4 p-3 bg-blue-500/20 border border-blue-500/30 rounded-lg">
                <p className="text-blue-200 text-sm">
                  💡 <strong>Note:</strong> Forum posts are stored as NFTs on the Sui blockchain. 
                  Your title (if you have one) will be displayed with your posts!
                </p>
              </div>
            </Card>
          </TabsContent>
        </Tabs>
      </div>

      {/* Footer */}
      <div className="max-w-6xl mx-auto mt-6 text-center">
        <p className="text-purple-300 text-sm">
          🔐 All posts are NFTs on Sui blockchain • Moderated by community
        </p>
      </div>
    </main>
  );
}
