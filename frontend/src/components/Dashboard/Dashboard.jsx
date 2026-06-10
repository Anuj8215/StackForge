import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getServices, deleteService } from "../../services/auth.jsx";
import AddServiceModal from "./AddServiceModal.jsx";
import TOTPCard from "./TOTPCard.jsx";
import { logout } from "../../utils/auth.jsx";

const Dashboard = () => {
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showAddModal, setShowAddModal] = useState(false);
  const [refreshInterval, setRefreshInterval] = useState(null);
  const navigate = useNavigate();

  const fetchServices = async () => {
    try {
      const servicesData = await getServices();
      setServices(servicesData);
      setError("");
    } catch (err) {
      setError("Failed to load your services. Please try again.");
      if (err.response?.status === 401) {
        logout();
        navigate("/login");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchServices();

    // Set up interval to refresh codes more frequently (every 1 second)
    // This ensures we catch the TOTP code change immediately when it occurs
    const interval = setInterval(() => {
      fetchServices();
    }, 1000);

    setRefreshInterval(interval);

    return () => {
      clearInterval(interval);
    };
  }, [navigate]);

  const handleDeleteService = async (serviceId) => {
    // Use a more stylish confirm dialog
    const confirmDelete = () => {
      return new Promise((resolve) => {
        // Create custom confirm dialog elements
        const overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        overlay.style.animation = 'fadeIn 0.3s forwards';
        
        const dialog = document.createElement('div');
        dialog.className = 'modal-content';
        dialog.style.width = '400px';
        dialog.style.textAlign = 'center';
        dialog.style.animation = 'slideUp 0.4s forwards';
        
        dialog.innerHTML = `
          <h3 style="margin-bottom:20px;font-size:22px;">Delete Authentication Service</h3>
          <p style="margin-bottom:30px;color:rgba(255,255,255,0.8)">Are you sure you want to delete this service? This action cannot be undone.</p>
          <div style="display:flex;gap:15px;justify-content:center;">
            <button id="cancel-btn" class="btn btn-secondary">Cancel</button>
            <button id="confirm-btn" class="btn btn-danger">Delete</button>
          </div>
        `;
        
        overlay.appendChild(dialog);
        document.body.appendChild(overlay);
        
        // Add button event listeners
        document.getElementById('cancel-btn').addEventListener('click', () => {
          overlay.style.animation = 'fadeIn 0.3s forwards reverse';
          dialog.style.animation = 'slideUp 0.3s forwards reverse';
          setTimeout(() => {
            document.body.removeChild(overlay);
            resolve(false);
          }, 300);
        });
        
        document.getElementById('confirm-btn').addEventListener('click', () => {
          overlay.style.animation = 'fadeIn 0.3s forwards reverse';
          dialog.style.animation = 'slideUp 0.3s forwards reverse';
          setTimeout(() => {
            document.body.removeChild(overlay);
            resolve(true);
          }, 300);
        });
      });
    };

    const confirmed = await confirmDelete();
    
    if (confirmed) {
      try {
        await deleteService(serviceId);
        // Animate the removal of the service from the list
        const updatedServices = services.filter((service) => service.id !== serviceId);
        setServices(updatedServices);
      } catch (err) {
        setError("Failed to delete service. Please try again.");
      }
    }
  };

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>Speaksy Auth</h1>
        <div className="actions">
          <button
            className="btn btn-primary"
            onClick={() => setShowAddModal(true)}
          >
            <span className="btn-icon">➕</span> Add Service
          </button>
          <button className="btn btn-secondary" onClick={handleLogout}>
            <span className="btn-icon">🚪</span> Logout
          </button>
        </div>
      </header>

      {error && <div className="error-message">{error}</div>}

      <div className="services-container">
        {loading ? (
          <div className="loading">
            <div className="loading-spinner">
              <div className="spinner-circle"></div>
              <div className="spinner-plane"></div>
            </div>
            <p>Preparing for take-off...</p>
          </div>
        ) : services.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🛫</div>
            <p>Your security dashboard is clear for departure!</p>
            <p>Click on "Add Service" to add your first authentication code.</p>
          </div>
        ) : (
          <div className="services-grid">
            {services.map((service) => (
              <TOTPCard
                key={service.id}
                service={service}
                onDelete={() => handleDeleteService(service.id)}
              />
            ))}
          </div>
        )}
      </div>

      {showAddModal && (
        <AddServiceModal
          onClose={() => setShowAddModal(false)}
          onServiceAdded={fetchServices}
        />
      )}
    </div>
  );
};

export default Dashboard;
