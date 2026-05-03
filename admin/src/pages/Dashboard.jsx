import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';

export default function Dashboard() {
  const [stats, setStats] = useState({ totalRides: 0, totalDrivers: 0, totalEarnings: 0 });
  const navigate = useNavigate();

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const { data } = await axios.get('/api/admin/stats', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setStats(data.data);
    } catch (err) {
      if (err.response?.status === 401) {
        localStorage.removeItem('adminToken');
        navigate('/login');
      }
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    navigate('/login');
  };

  return (
    <div className="admin-layout">
      {/* Sidebar */}
      <div className="sidebar">
        <div className="sidebar-logo">Admin Panel</div>
        <Link to="/" className="nav-link active">Dashboard</Link>
        <Link to="/verifications" className="nav-link">Driver Approvals</Link>
      </div>

      {/* Main Content */}
      <div className="main-content">
        <div className="header">
          <button className="logout-btn" onClick={handleLogout}>Logout</button>
        </div>
        
        <div className="content-body">
          <h2 style={{ marginBottom: '20px' }}>Platform Overview</h2>
          <div className="stats-grid">
            <div className="stat-card">
              <div className="stat-title">Total Rides</div>
              <div className="stat-value">{stats.totalRides}</div>
            </div>
            <div className="stat-card">
              <div className="stat-title">Registered Drivers</div>
              <div className="stat-value">{stats.totalDrivers}</div>
            </div>
            <div className="stat-card">
              <div className="stat-title">Platform Earnings</div>
              <div className="stat-value">৳{stats.totalEarnings}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
