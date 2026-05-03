import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';

export default function DriverVerifications() {
  const [drivers, setDrivers] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    fetchPendingDrivers();
  }, []);

  const fetchPendingDrivers = async () => {
    try {
      const token = localStorage.getItem('adminToken');
      const { data } = await axios.get('/api/admin/drivers/pending', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setDrivers(data.data);
    } catch (err) {
      if (err.response?.status === 401) {
        navigate('/login');
      }
    }
  };

  const handleVerify = async (id, status) => {
    try {
      const token = localStorage.getItem('adminToken');
      await axios.put(`/api/admin/drivers/${id}/verify`, { status }, {
        headers: { Authorization: `Bearer ${token}` }
      });
      fetchPendingDrivers(); // Refresh list
    } catch (err) {
      alert('Failed to update status');
    }
  };

  return (
    <div className="admin-layout">
      {/* Sidebar */}
      <div className="sidebar">
        <div className="sidebar-logo">Admin Panel</div>
        <Link to="/" className="nav-link">Dashboard</Link>
        <Link to="/verifications" className="nav-link active">Driver Approvals</Link>
      </div>

      {/* Main Content */}
      <div className="main-content">
        <div className="header">
          <button className="logout-btn" onClick={() => navigate('/login')}>Logout</button>
        </div>
        
        <div className="content-body">
          <h2 style={{ marginBottom: '20px' }}>Pending Approvals</h2>
          <div className="card">
            <div className="card-header">Driver Documents</div>
            <table>
              <thead>
                <tr>
                  <th>Driver Info</th>
                  <th>License Plate</th>
                  <th>NID Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {drivers.map(driver => (
                  <tr key={driver.id}>
                    <td>
                      <div style={{ fontWeight: 600 }}>{driver.users?.full_name || 'Unknown'}</div>
                      <div style={{ fontSize: '12px', color: '#64748B' }}>{driver.users?.phone || 'Unknown'}</div>
                    </td>
                    <td>{driver.vehicle_plate_number}</td>
                    <td>
                      <span className={`status-badge status-${driver.verification_status}`}>
                        {driver.verification_status}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '10px' }}>
                        <button 
                          className="btn btn-sm btn-success"
                          onClick={() => handleVerify(driver.user_id, 'approved')}
                        >Approve</button>
                        <button 
                          className="btn btn-sm btn-danger"
                          onClick={() => handleVerify(driver.user_id, 'rejected')}
                        >Reject</button>
                      </div>
                    </td>
                  </tr>
                ))}
                {drivers.length === 0 && (
                  <tr>
                    <td colSpan="4" style={{ textAlign: 'center', padding: '40px', color: '#64748B' }}>
                      No pending verifications.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
