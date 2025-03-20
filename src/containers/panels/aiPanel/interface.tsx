export interface AIPanelProps {
  t: (title: string) => string;
  isAIDrawerOpen: boolean;
  handleOpenAIDrawer: (isOpen: boolean) => void;
  currentBook: any;
  currentChapter: string;
}

export interface AIPanelState {
  currentTab: string;
  isTouching: boolean;
  startX: number;
} 