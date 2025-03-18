import {
  handleFetchNotes,
  handleFetchBookmarks,
  handleFetchBooks,
  handleReadingBook,
  handleFetchPercentage,
  handleReaderMode,
  handleMenuMode,
  handleOriginalText,
  handleOpenMenu,
  handleAIDrawerOpen,
} from "../../store/actions";
import { connect } from "react-redux";
import { stateType } from "../../store";
import Reader from "./component";
import { withTranslation } from "react-i18next";

const mapStateToProps = (state: stateType) => {
  return {
    currentBook: state.book.currentBook,
    bookmarks: state.reader.bookmarks,
    chapters: state.reader.chapters,
    htmlBook: state.reader.htmlBook,
    percentage: state.progressPanel.percentage,
    readerMode: state.reader.readerMode,
    isNavLocked: state.reader.isNavLocked,
    isSearch: state.book.isSearch,
    isAIDrawerOpen: state.reader.isAIDrawerOpen,
  };
};
const actionCreator = {
  handleFetchNotes,
  handleFetchBookmarks,
  handleFetchBooks,
  handleReadingBook,
  handleFetchPercentage,
  handleReaderMode,
  handleMenuMode,
  handleOriginalText,
  handleOpenMenu,
  handleOpenAIDrawer: handleAIDrawerOpen,
};
export default connect(
  mapStateToProps,
  actionCreator
)(withTranslation()(Reader as any) as any);
