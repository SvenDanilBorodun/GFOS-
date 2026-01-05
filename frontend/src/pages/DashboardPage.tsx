import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  LightBulbIcon,
  UserGroupIcon,
  HeartIcon,
  ChatBubbleLeftRightIcon,
  ArrowTrendingUpIcon,
  ChartBarIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';
import { TrophyIcon, FireIcon } from '@heroicons/react/24/solid';
import { dashboardService } from '../services/dashboardService';
import { DashboardStats, TopIdea, Idea, Survey } from '../types';
import { format } from 'date-fns';

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [topIdeas, setTopIdeas] = useState<TopIdea[]>([]);
  const [newIdeas, setNewIdeas] = useState<Idea[]>([]);
  const [surveys, setSurveys] = useState<Survey[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const [statsData, topIdeasData, newIdeasData, surveysData] = await Promise.all([
          dashboardService.getStats(),
          dashboardService.getTopIdeas(),
          dashboardService.getNewIdeas(5),
          dashboardService.getActiveSurveys(),
        ]);
        setStats(statsData);
        setTopIdeas(topIdeasData);
        setNewIdeas(newIdeasData);
        setSurveys(surveysData);
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-primary-600" />
      </div>
    );
  }

  const statCards = [
    {
      name: 'Total Ideas',
      value: stats?.totalIdeas || 0,
      icon: LightBulbIcon,
      color: 'bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400',
    },
    {
      name: 'Active Users',
      value: stats?.totalUsers || 0,
      icon: UserGroupIcon,
      color: 'bg-success-50 dark:bg-success-900/20 text-success-600 dark:text-success-400',
    },
    {
      name: 'Total Likes',
      value: stats?.totalLikes || 0,
      icon: HeartIcon,
      color: 'bg-error-50 dark:bg-error-900/20 text-error-600 dark:text-error-400',
    },
    {
      name: 'Comments',
      value: stats?.totalComments || 0,
      icon: ChatBubbleLeftRightIcon,
      color: 'bg-warning-50 dark:bg-warning-900/20 text-warning-600 dark:text-warning-400',
    },
  ];

  const getRankIcon = (rank: number) => {
    switch (rank) {
      case 1:
        return <TrophyIcon className="w-6 h-6 text-yellow-500" />;
      case 2:
        return <TrophyIcon className="w-6 h-6 text-gray-400" />;
      case 3:
        return <TrophyIcon className="w-6 h-6 text-amber-700" />;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
          <p className="text-gray-600 dark:text-gray-400">
            Welcome back! Here's what's happening with your ideas.
          </p>
        </div>
        <Link to="/ideas/new" className="btn-primary">
          Submit New Idea
        </Link>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((stat) => (
          <div key={stat.name} className="card p-5">
            <div className="flex items-center gap-4">
              <div className={`p-3 rounded-xl ${stat.color}`}>
                <stat.icon className="w-6 h-6" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stat.value.toLocaleString()}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">{stat.name}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Top 3 Ideas of the Week */}
        <div className="lg:col-span-2 card">
          <div className="p-5 border-b border-gray-100 dark:border-gray-700">
            <div className="flex items-center gap-2">
              <FireIcon className="w-5 h-5 text-orange-500" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Top 3 Ideas of the Week
              </h2>
            </div>
          </div>
          <div className="divide-y divide-gray-100 dark:divide-gray-700">
            {topIdeas.length === 0 ? (
              <div className="p-8 text-center text-gray-500 dark:text-gray-400">
                No ideas this week yet. Be the first to submit!
              </div>
            ) : (
              topIdeas.map((item) => (
                <Link
                  key={item.idea.id}
                  to={`/ideas/${item.idea.id}`}
                  className="flex items-center gap-4 p-5 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <div className="flex-shrink-0">{getRankIcon(item.rank)}</div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-gray-900 dark:text-white truncate">
                      {item.idea.title}
                    </h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      by {item.idea.author.firstName} {item.idea.author.lastName}
                    </p>
                  </div>
                  <div className="flex items-center gap-4 text-sm">
                    <div className="flex items-center gap-1 text-red-500">
                      <HeartIcon className="w-4 h-4" />
                      <span>{item.weeklyLikes}</span>
                    </div>
                    <span className={`badge ${
                      item.idea.status === 'COMPLETED' ? 'badge-success' :
                      item.idea.status === 'IN_PROGRESS' ? 'badge-warning' : 'badge-gray'
                    }`}>
                      {item.idea.status.replace('_', ' ')}
                    </span>
                  </div>
                </Link>
              ))
            )}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="space-y-6">
          {/* Ideas by status */}
          <div className="card p-5">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Ideas by Status
            </h2>
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600 dark:text-gray-400">Concept</span>
                  <span className="font-medium text-gray-900 dark:text-white">
                    {stats?.conceptIdeas || 0}
                  </span>
                </div>
                <div className="progress-bar">
                  <div
                    className="progress-bar-fill bg-gray-400"
                    style={{
                      width: `${((stats?.conceptIdeas || 0) / (stats?.totalIdeas || 1)) * 100}%`,
                    }}
                  />
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600 dark:text-gray-400">In Progress</span>
                  <span className="font-medium text-gray-900 dark:text-white">
                    {stats?.inProgressIdeas || 0}
                  </span>
                </div>
                <div className="progress-bar">
                  <div
                    className="progress-bar-fill bg-warning-500"
                    style={{
                      width: `${((stats?.inProgressIdeas || 0) / (stats?.totalIdeas || 1)) * 100}%`,
                    }}
                  />
                </div>
              </div>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className="text-gray-600 dark:text-gray-400">Completed</span>
                  <span className="font-medium text-gray-900 dark:text-white">
                    {stats?.completedIdeas || 0}
                  </span>
                </div>
                <div className="progress-bar">
                  <div
                    className="progress-bar-fill bg-success-500"
                    style={{
                      width: `${((stats?.completedIdeas || 0) / (stats?.totalIdeas || 1)) * 100}%`,
                    }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Popular category */}
          <div className="card p-5">
            <div className="flex items-center gap-2 mb-3">
              <ChartBarIcon className="w-5 h-5 text-primary-600" />
              <h2 className="font-semibold text-gray-900 dark:text-white">Most Popular Category</h2>
            </div>
            <p className="text-2xl font-bold text-primary-600">
              {stats?.popularCategory || 'N/A'}
            </p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* New Ideas */}
        <div className="card">
          <div className="p-5 border-b border-gray-100 dark:border-gray-700">
            <div className="flex items-center gap-2">
              <ArrowTrendingUpIcon className="w-5 h-5 text-primary-600" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Recently Submitted
              </h2>
            </div>
          </div>
          <div className="divide-y divide-gray-100 dark:divide-gray-700">
            {newIdeas.length === 0 ? (
              <div className="p-8 text-center text-gray-500 dark:text-gray-400">
                No recent ideas
              </div>
            ) : (
              newIdeas.map((idea) => (
                <Link
                  key={idea.id}
                  to={`/ideas/${idea.id}`}
                  className="block p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <h3 className="font-medium text-gray-900 dark:text-white truncate mb-1">
                    {idea.title}
                  </h3>
                  <div className="flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
                    <span className="badge-gray">{idea.category}</span>
                    <div className="flex items-center gap-1">
                      <ClockIcon className="w-4 h-4" />
                      {format(new Date(idea.createdAt), 'MMM d')}
                    </div>
                  </div>
                </Link>
              ))
            )}
          </div>
          <div className="p-4 border-t border-gray-100 dark:border-gray-700">
            <Link to="/ideas" className="text-sm text-primary-600 dark:text-primary-400 hover:underline">
              View all ideas
            </Link>
          </div>
        </div>

        {/* Active Surveys */}
        <div className="card">
          <div className="p-5 border-b border-gray-100 dark:border-gray-700">
            <div className="flex items-center gap-2">
              <ChartBarIcon className="w-5 h-5 text-secondary-600" />
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Active Surveys
              </h2>
            </div>
          </div>
          <div className="divide-y divide-gray-100 dark:divide-gray-700">
            {surveys.length === 0 ? (
              <div className="p-8 text-center text-gray-500 dark:text-gray-400">
                No active surveys
              </div>
            ) : (
              surveys.slice(0, 3).map((survey) => (
                <Link
                  key={survey.id}
                  to={`/surveys?id=${survey.id}`}
                  className="block p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors"
                >
                  <h3 className="font-medium text-gray-900 dark:text-white truncate mb-2">
                    {survey.question}
                  </h3>
                  <div className="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
                    <span>{survey.totalVotes} votes</span>
                    <span>by {survey.creator.firstName}</span>
                  </div>
                </Link>
              ))
            )}
          </div>
          <div className="p-4 border-t border-gray-100 dark:border-gray-700">
            <Link to="/surveys" className="text-sm text-primary-600 dark:text-primary-400 hover:underline">
              View all surveys
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
