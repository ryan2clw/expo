import React from 'react';
import { ScrollView, Text } from 'react-native';
import * as ScreenOrientation from 'expo-screen-orientation';
import { Platform, Subscription } from '@unimodules/core';
import ListButton from '../components/ListButton';

interface State {
  orientation?: ScreenOrientation.Orientation;
  orientationLock?: ScreenOrientation.OrientationLock;
}

export default class ScreenOrientationScreen extends React.Component<{}, State> {
  static navigationOptions = {
    title: 'ScreenOrientation',
  };

  readonly state: State = {};

  listener?: Subscription;

  async componentDidMount() {
    this.listener = ScreenOrientation.addOrientationChangeListener(
      ({ orientation, orientationLock }) => {
        this.setState({
          orientation,
          orientationLock,
        });
      }
    );

    await this.updateCurrentOrienationAndLock();
  }

  updateCurrentOrienationAndLock = async () => {
    const [orientation, orientationLock] = await Promise.all([
      ScreenOrientation.getOrientationAsync(),
      ScreenOrientation.getOrientationLockAsync(),
    ]);

    // update state
    this.setState({
      orientation,
      orientationLock,
    });
  };

  updateOrientationAsync = async () => {
    this.setState({
      orientation: await ScreenOrientation.getOrientationAsync(),
    });
  };

  componentWillUnmount() {
    if (this.listener) {
      this.listener.remove();
    }
  }

  lock = async (orientation: ScreenOrientation.OrientationLock) => {
    if (Platform.OS === 'web') {
      // most web browsers require fullscreen in order to change screen orientation
      await document.documentElement.requestFullscreen();
    }

    await ScreenOrientation.lockAsync(orientation).catch(console.warn); // on iPhoneX PortraitUpsideDown would be rejected

    if (Platform.OS === 'web') {
      await document.exitFullscreen();
    }

    await this.updateCurrentOrienationAndLock();
  };

  lockPlatformExample = async () => {
    if (Platform.OS === 'web') {
      // most web browsers require fullscreen in order to change screen orientation
      await document.documentElement.requestFullscreen();
    }

    await ScreenOrientation.lockPlatformAsync({
      screenOrientationLockWeb: ScreenOrientation.WebOrientationLock.LANDSCAPE,
      screenOrientationArrayIOS: [
        ScreenOrientation.Orientation.PORTRAIT_DOWN,
        ScreenOrientation.Orientation.LANDSCAPE_RIGHT,
      ],
      screenOrientationConstantAndroid: 8, // reverse landscape
    }).catch(e => alert(e)); // on iPhoneX PortraitUpsideDown would be rejected

    if (Platform.OS === 'web') {
      await document.exitFullscreen();
    }

    await this.updateCurrentOrienationAndLock();
  };

  doesSupport = async () => {
    const result = await ScreenOrientation.supportsOrientationLockAsync(
      ScreenOrientation.OrientationLock.PORTRAIT_DOWN
    ).catch(console.warn);
    alert(`Orientation.PORTRAIT_DOWN supported: ${JSON.stringify(result)}`);
  };

  unlock = async () => {
    await ScreenOrientation.unlockAsync().catch(console.warn);

    await this.updateCurrentOrienationAndLock();
  };

  getScreenOrienationLockOptions(): Array<{
    key: string;
    value: ScreenOrientation.OrientationLock;
  }> {
    const orientationOptions = [
      ScreenOrientation.OrientationLock.DEFAULT,
      ScreenOrientation.OrientationLock.ALL,
      ScreenOrientation.OrientationLock.PORTRAIT,
      ScreenOrientation.OrientationLock.PORTRAIT_UP,
      ScreenOrientation.OrientationLock.PORTRAIT_DOWN,
      ScreenOrientation.OrientationLock.LANDSCAPE,
      ScreenOrientation.OrientationLock.LANDSCAPE_LEFT,
      ScreenOrientation.OrientationLock.LANDSCAPE_RIGHT,
    ];

    if (Platform.OS === 'ios') {
      orientationOptions.push(ScreenOrientation.OrientationLock.ALL_BUT_UPSIDE_DOWN);
    }

    return orientationOptions.map(orientation => ({
      key: ScreenOrientation.OrientationLock[orientation],
      value: orientation,
    }));
  }

  render() {
    const { orientation, orientationLock } = this.state;
    return (
      <ScrollView style={{ padding: 10 }}>
        {orientation !== undefined && (
          <Text>Orientation: {ScreenOrientation.Orientation[orientation]}</Text>
        )}
        {orientationLock !== undefined && (
          <Text>OrientationLock: {ScreenOrientation.OrientationLock[orientationLock]}</Text>
        )}
        {this.getScreenOrienationLockOptions().map(o => (
          <ListButton key={o.key} onPress={() => this.lock(o.value)} title={o.key} />
        ))}
        <ListButton
          key="lockPlatformAsync Example"
          onPress={this.lockPlatformExample}
          title="Apply a custom native lock"
        />
        <ListButton
          key="doesSupport"
          onPress={this.doesSupport}
          title="Check Orientation.PORTRAIT_DOWN support"
        />
        <ListButton
          key="unlock"
          onPress={this.unlock}
          title="unlock orientation back to default settings"
        />
      </ScrollView>
    );
  }
}
