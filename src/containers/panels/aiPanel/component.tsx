import React from "react";
import "./aiPanel.css";
import { Trans } from "react-i18next";
import { AIPanelProps, AIPanelState } from "./interface";

class AIPanel extends React.Component<AIPanelProps, AIPanelState> {
  constructor(props: AIPanelProps) {
    super(props);
    this.state = {
      currentTab: "summarize",
      isTouching: false,
      startX: 0
    };
  }

  handleClose = () => {
    this.props.handleOpenAIDrawer(false);
  };

  handleOptionClick = (tab: string) => {
    this.setState({ currentTab: tab });
    // TODO: Implement AI features based on selected tab
    console.log("Selected tab:", tab);
  };

  // Touch event handlers for mobile swipe gestures
  handleTouchStart = (e: React.TouchEvent) => {
    this.setState({
      isTouching: true,
      startX: e.touches[0].clientX
    });
  };

  handleTouchMove = (e: React.TouchEvent) => {
    if (!this.state.isTouching) return;
    
    const currentX = e.touches[0].clientX;
    const diff = this.state.startX - currentX;
    
    // If swiping left more than 50px, close the drawer
    if (diff > 50) {
      this.handleClose();
      this.setState({ isTouching: false });
    }
  };

  handleTouchEnd = () => {
    this.setState({ isTouching: false });
  };

  render() {
    const { t } = this.props;
    
    return (
      <div 
        className="ai-panel-parent"
        onTouchStart={this.handleTouchStart}
        onTouchMove={this.handleTouchMove}
        onTouchEnd={this.handleTouchEnd}
      >
        <div className="ai-panel-title">
          <Trans>AI Reading Assistant</Trans>
        </div>
        <span 
          className="icon-close ai-panel-close" 
          onClick={this.handleClose}
        ></span>
        
        <div className="ai-panel-section">
          <div className="ai-panel-section-title">
            <Trans>Chapter Tools</Trans>
          </div>
          <div 
            className="ai-panel-option" 
            onClick={() => this.handleOptionClick("summarize")}
          >
            <div className="ai-panel-option-icon summarize">📝</div>
            <div className="ai-panel-option-text">
              <div className="ai-panel-option-title">
                <Trans>Summarize Chapter</Trans>
              </div>
              <div className="ai-panel-option-desc">
                <Trans>Get a concise summary</Trans>
              </div>
            </div>
          </div>
          
          <div 
            className="ai-panel-option" 
            onClick={() => this.handleOptionClick("chat")}
          >
            <div className="ai-panel-option-icon chat">💬</div>
            <div className="ai-panel-option-text">
              <div className="ai-panel-option-title">
                <Trans>Chat about Chapter</Trans>
              </div>
              <div className="ai-panel-option-desc">
                <Trans>Ask questions and discuss</Trans>
              </div>
            </div>
          </div>
        </div>
        
        <div className="ai-panel-section">
          <div className="ai-panel-section-title">
            <Trans>Learning Aids</Trans>
          </div>
          <div 
            className="ai-panel-option" 
            onClick={() => this.handleOptionClick("explain")}
          >
            <div className="ai-panel-option-icon explain">🔍</div>
            <div className="ai-panel-option-text">
              <div className="ai-panel-option-title">
                <Trans>Explain Concepts</Trans>
              </div>
              <div className="ai-panel-option-desc">
                <Trans>Explore complex ideas</Trans>
              </div>
            </div>
          </div>
          
          <div 
            className="ai-panel-option" 
            onClick={() => this.handleOptionClick("terms")}
          >
            <div className="ai-panel-option-icon terms">📚</div>
            <div className="ai-panel-option-text">
              <div className="ai-panel-option-title">
                <Trans>Define Terms</Trans>
              </div>
              <div className="ai-panel-option-desc">
                <Trans>Understand difficult words</Trans>
              </div>
            </div>
          </div>
        </div>
        
        {/* TODO: Add more AI features here as needed */}
      </div>
    );
  }
}

export default AIPanel; 