import { connect } from "react-redux";
import { withTranslation } from "react-i18next";
import AIButton from "./component";
import { stateType } from "../../store";
import { handleAIDrawerOpen } from "../../store/actions/reader";

const mapStateToProps = (state: stateType) => {
  return {
    isAIDrawerOpen: state.reader.isAIDrawerOpen,
  };
};

const actionCreator = {
  handleOpenAIDrawer: handleAIDrawerOpen,
};

export default connect(
  mapStateToProps,
  actionCreator
)(withTranslation()(AIButton as any) as any); 