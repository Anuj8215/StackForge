import React, { useState, useEffect } from "react";
import { registerService, registerServiceScan } from "../../services/auth.jsx";

const AddServiceModal = ({ onClose, onServiceAdded }) => {
  const [activeTab, setActiveTab] = useState("manual");
  const [manualFormData, setManualFormData] = useState({
    name: "",
    secret: "",
    issuer: "",
  });
  const [scanFormData, setScanFormData] = useState({
    otpauth_url: "",
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleManualChange = (e) => {
    setManualFormData({ ...manualFormData, [e.target.name]: e.target.value });
  };

  const handleScanChange = (e) => {
    setScanFormData({ ...scanFormData, [e.target.name]: e.target.value });
  };

  const handleManualSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await registerService(
        manualFormData.name,
        manualFormData.secret,
        manualFormData.issuer
      );
      onServiceAdded();
      onClose();
    } catch (err) {
      setError(
        err.response?.data?.error ||
        "Failed to add service. Please check your inputs."
      );
    } finally {
      setLoading(false);
    }
  };

  const handleScanSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await registerServiceScan(scanFormData.otpauth_url);
      onServiceAdded();
      onClose();
    } catch (err) {
      setError(
        err.response?.data?.error ||
        "Failed to add service. Invalid OTP auth URL."
      );
    } finally {
      setLoading(false);
    }
  };


  useEffect(() => {
    // Add animation order to each form group
    const formGroups = document.querySelectorAll('.modal-content .form-group');
    formGroups.forEach((group, index) => {
      group.style.setProperty('--animation-order', index);
    });
  }, [activeTab]);


  const handleModalClose = () => {
    const modalOverlay = document.querySelector('.modal-overlay');
    const modalContent = document.querySelector('.modal-content');

    // Apply closing animations
    if (modalOverlay && modalContent) {
      modalOverlay.style.animation = 'fadeIn 0.3s forwards reverse';
      modalContent.style.animation = 'slideUp 0.3s forwards reverse';

      // Wait for animation to complete before actually closing
      setTimeout(onClose, 300);
    } else {
      onClose();
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-header">
          <h2>Add Security Pass 🧑🏻‍💻</h2>
          <button className="close-btn" onClick={handleModalClose}>
            ×
          </button>
        </div>

        <div className="modal-tabs">
          <button
            className={`tab-btn ${activeTab === "manual" ? "active" : ""}`}
            onClick={() => setActiveTab("manual")}
          >
            <span className="tab-icon"></span> Manual Entry
          </button>
          <button
            className={`tab-btn ${activeTab === "scan" ? "active" : ""}`}
            onClick={() => setActiveTab("scan")}
          >
            <span className="tab-icon"></span> Enter OTP URL
          </button>
        </div>

        {error && <div className="error-message">{error}</div>}

        {activeTab === "manual" ? (
          <form onSubmit={handleManualSubmit}>
            <div className="form-group">
              <label htmlFor="name">Service Name *</label>
              <input
                type="text"
                id="name"
                name="name"
                value={manualFormData.name}
                onChange={handleManualChange}
                required
              />
            </div>
            <div className="form-group">
              <label htmlFor="secret">Secret Key *</label>
              <input
                type="text"
                id="secret"
                name="secret"
                value={manualFormData.secret}
                onChange={handleManualChange}
                placeholder="e.g. JBSWY3DPEHPK3PXP"
                required
              />
              <small>
                The secret key provided by the service (Base32 format)
              </small>
            </div>
            <div className="form-group">
              <label htmlFor="issuer">Service Provider</label>
              <input
                type="text"
                id="issuer"
                name="issuer"
                value={manualFormData.issuer}
                onChange={handleManualChange}
                placeholder="e.g. Google, GitHub"
              />
              <small>Optional: The name of the company/service provider</small>
            </div>
            <div className="form-actions">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={onClose}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={loading}
              >
                {loading ? "Adding..." : "Add Service"}
              </button>
            </div>
          </form>
        ) : (
          <form onSubmit={handleScanSubmit}>
            <div className="form-group">
              <label htmlFor="otpauth_url">OTP Auth URL *</label>
              <input
                type="text"
                id="otpauth_url"
                name="otpauth_url"
                value={scanFormData.otpauth_url}
                onChange={handleScanChange}
                placeholder="otpauth://totp/..."
                required
              />
              <small>Enter the OTP URL from the QR code</small>
            </div>
            <div className="form-actions">
              <button
                type="button"
                className="btn btn-secondary"
                onClick={onClose}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="btn btn-primary"
                disabled={loading}
              >
                {loading ? "Adding..." : "Add Service"}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

export default AddServiceModal;
