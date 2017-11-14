import UserInfo from './UserInfo';
import {
	NativeModules
} from 'react-native';

const {
	TwilioChatClient
} = NativeModules;

class Member {
  constructor(props) {
    this.identity = props.identity
    this.lastConsumedMessageIndex = props.lastConsumedMessageIndex;
    this.lastConsumptionTimestamp = this.lastConsumptionTimestamp ? new Date(this.lastConsumptionTimestamp) : null;
  }

  getUser() {
    return TwilioChatClient.getUser(this.identity)
      .then(data => new UserInfo(data))
  }
}

export default Member;
