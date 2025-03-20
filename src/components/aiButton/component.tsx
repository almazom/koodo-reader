import React from "react";
import "./aiButton.css";
import { AIButtonProps, AIButtonState } from "./interface";
import { Trans } from "react-i18next";
import { Tooltip } from "react-tooltip";

class AIButton extends React.Component<AIButtonProps, AIButtonState> {
  constructor(props: AIButtonProps) {
    super(props);
    this.state = {
      isHovering: false
    };
  }

  handleMouseEnter = () => {
    this.setState({ isHovering: true });
  };

  handleMouseLeave = () => {
    this.setState({ isHovering: false });
  };

  handleClick = () => {
    // Explicitly toggle the drawer state using the current value
    this.props.handleOpenAIDrawer(!this.props.isAIDrawerOpen);
    console.log("AI Button clicked, toggling drawer to:", !this.props.isAIDrawerOpen);
  };

  render() {
    const { t } = this.props;
    
    return (
      <div className="ai-button-container">
        <button 
          className="ai-button"
          id="ai-button"
          onClick={this.handleClick}
          onMouseEnter={this.handleMouseEnter}
          onMouseLeave={this.handleMouseLeave}
          data-tooltip-id="ai-button-tooltip"
          data-tooltip-content={t("AI Assistant")}
          aria-label={t("AI Assistant")}
        >
          AI
        </button>
        <Tooltip id="ai-button-tooltip" place="left" />
      </div>
    );
  }
}

export default AIButton; 