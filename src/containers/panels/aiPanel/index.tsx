import { connect } from "react-redux";
import { withTranslation } from "react-i18next";
import AIPanel from "./component";
import { stateType } from "../../../store";
import { handleAIDrawerOpen } from "../../../store/actions/reader";

const mapStateToProps = (state: stateType) => {
  return {
    isAIDrawerOpen: state.reader.isAIDrawerOpen,
    currentBook: state.book.currentBook,
    currentChapter: state.reader.currentChapter
  };
};

const actionCreator = {
  handleOpenAIDrawer: handleAIDrawerOpen,
};

export default connect(
  mapStateToProps,
  actionCreator
)(withTranslation()(AIPanel as any) as any); 