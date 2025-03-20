export interface AIButtonProps {
  handleOpenAIDrawer: (isOpen: boolean) => void;
  isAIDrawerOpen: boolean;
  t: (title: string) => string;
}

export interface AIButtonState {
  isHovering: boolean;
} 