import React, { useState, useEffect } from 'react';
import { Trans } from 'react-i18next';
import './pwa.css';

// BeforeInstallPromptEvent is not part of the standard TypeScript types yet
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

const PwaPrompt: React.FC = () => {
  const [showPrompt, setShowPrompt] = useState<boolean>(false);
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);
  
  useEffect(() => {
    const handleBeforeInstallPrompt = (e: Event) => {
      // Prevent Chrome 76+ from automatically showing the prompt
      e.preventDefault();
      // Store the event for later use
      setDeferredPrompt(e as BeforeInstallPromptEvent);
      // Show custom install prompt
      setShowPrompt(true);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    
    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);
  
  const handleInstallClick = () => {
    if (!deferredPrompt) return;
    
    // Show the browser's install prompt
    deferredPrompt.prompt();
    
    // Wait for the user to respond to the prompt
    deferredPrompt.userChoice.then((choiceResult) => {
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the PWA installation');
      } else {
        console.log('User declined the PWA installation');
      }
      // Clear the saved prompt
      setDeferredPrompt(null);
      // Hide our custom prompt
      setShowPrompt(false);
    });
  };
  
  const handleDismiss = () => {
    setShowPrompt(false);
  };
  
  if (!showPrompt) return null;
  
  return (
    <div className="pwa-install-prompt">
      <div className="prompt-content">
        <h3><Trans>Install Koodo Reader App</Trans></h3>
        <p><Trans>Install this application on your device for quick and easy access when you're on the go.</Trans></p>
        <div className="prompt-buttons">
          <button 
            className="dismiss-btn"
            onClick={handleDismiss}
          >
            <Trans>Not now</Trans>
          </button>
          <button 
            className="install-btn"
            onClick={handleInstallClick}
          >
            <Trans>Install</Trans>
          </button>
        </div>
      </div>
    </div>
  );
};

export default PwaPrompt; 