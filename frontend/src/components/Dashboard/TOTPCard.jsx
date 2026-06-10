import React, { useState, useEffect, useRef } from "react";
import { CircularProgressbar, buildStyles } from "react-circular-progressbar";
import "react-circular-progressbar/dist/styles.css";

const TOTPCard = ({ service, onDelete }) => {
  const [timeRemaining, setTimeRemaining] = useState(service.timeRemaining);
  const [code, setCode] = useState(service.code);
  const [isCodeRefreshed, setIsCodeRefreshed] = useState(false);
  const codeRef = useRef(null);

  useEffect(() => {
    // Check if the code has changed from the previous one
    if (code !== service.code) {
      setIsCodeRefreshed(true);
      setTimeout(() => setIsCodeRefreshed(false), 1000);
    }
    
    setCode(service.code);
    setTimeRemaining(service.timeRemaining);

    // Update time remaining every second
    const timer = setInterval(() => {
      setTimeRemaining((prevTime) => {
        if (prevTime <= 1) {
          // When time is up, do nothing - the parent component will refresh the data
          return 0;
        }
        return prevTime - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [service.code, service.timeRemaining, code]);

  // Group code in pairs for better readability (e.g., "123 456")
  const formattedCode = code
    .toString()
    .padStart(6, "0")
    .match(/.{1,3}/g)
    .join(" ");

  // Calculate percentage for the circular progress
  const percentage = (timeRemaining / 30) * 100;

  // Get a consistent but random airline theme color based on service name
  const getServiceColor = (name) => {
    const colors = [
      '#00a2ff', // Sky Airlines blue
      '#3066BE', // Deep Sky Blue
      '#3066BE', // Royal Blue
      '#5C9EAD', // Cadet Blue
      '#005082', // Yale Blue
    ];
    
    // Use string hash to get consistent color for the same service name
    const hash = name.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    return colors[hash % colors.length];
  };
  
  const serviceColor = getServiceColor(service.name);

  return (
    <div className="totp-card" style={{ borderTop: `4px solid ${serviceColor}` }}>
      <div className="totp-card-header">
        <div className="service-icon" style={{ backgroundColor: serviceColor }}>
          {service.name.charAt(0).toUpperCase()}
        </div>
        <div className="service-info">
          <h3>{service.name}</h3>
          {service.issuer && <div className="issuer">{service.issuer}</div>}
        </div>
        <button className="delete-btn" onClick={onDelete} title="Delete">
          ✕
        </button>
      </div>

      <div className="totp-card-content">
        <div 
          className={`code ${isCodeRefreshed ? 'code-refreshed' : ''}`} 
          ref={codeRef}
          style={{
            animation: isCodeRefreshed ? 'codeRefresh 0.8s ease' : 'none'
          }}
        >
          {formattedCode}
        </div>

        <div className="timer" style={{ position: 'relative' }}>
          {/* Time almost up alert */}
          {percentage <= 20 && (
            <div className="time-alert" style={{
              position: 'absolute',
              top: -8,
              right: -8,
              width: 12,
              height: 12,
              backgroundColor: '#ff5e62',
              borderRadius: '50%',
              animation: 'pulse 1s infinite',
              boxShadow: '0 0 10px #ff5e62'
            }}></div>
          )}
          
          <div style={{ width: 70, height: 70 }}>
            <CircularProgressbar
              value={percentage}
              text={`${timeRemaining}s`}
              styles={buildStyles({
                textSize: "28px",
                textColor: "#ffffff",
                pathColor: 
                  percentage > 66 ? "#00a2ff" :  // Sky Airlines blue when plenty of time
                  percentage > 33 ? "#ffbd39" :  // Amber/yellow when moderate time
                  "#ff5e62",                     // Red when low time
                trailColor: "rgba(255, 255, 255, 0.2)",
                pathTransition: "stroke-dashoffset 0.5s ease",
                strokeLinecap: "round",
                // Add pulse animation when time is running low
                pathTransitionDuration: percentage < 20 ? 0.5 : 0.3,
                rotation: 0.5,
              })}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default TOTPCard;
