import { capitalizeAll, multiline } from 'common/string';
import { useBackend } from 'tgui/backend';
import {
  Button,
  Icon,
  LabeledControls,
  NoticeBox,
  Section,
  Slider,
  Stack,
  Tooltip,
} from 'tgui/components';
import { Window } from 'tgui/layouts';

type SimpleBotContext = {
  can_hack: number;
  locked: number;
  emagged: number;
  has_access: number;
  settings: Settings;
  custom_controls: Controls;
};

type Settings = {
  power: number;
  airplane_mode: number;
  maintenance_lock: number;
  patrol_station: number;
  allow_possession: number;
  possession_enabled: number;
  has_personality: number;
};

type Controls = {
  [Control: string]: [Value: number];
};

export const SimpleBot = (props) => {
  const { data } = useBackend<SimpleBotContext>();
  const { can_hack, locked } = data;
  const access = !locked || can_hack;

  return (
    <Window width={450} height={300}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Settings" buttons={<TabDisplay />}>
              {!access ? <NoticeBox>Locked!</NoticeBox> : <SettingsDisplay />}
            </Section>
          </Stack.Item>
          {access && (
            <Stack.Item grow>
              <Section fill scrollable title="Controls">
                <ControlsDisplay />
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** Creates a lock button at the top of the controls */
const TabDisplay = (props) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { can_hack, has_access, locked } = data;

  return (
    <>
      {!!can_hack && <HackButton />}
      <Button
        color="transparent"
        icon="fa-poll-h"
        onClick={() => act('rename')}
        tooltip="Update the bot's name registration."
      >
        Rename
      </Button>
      <Button
        color="transparent"
        disabled={!has_access && !can_hack}
        icon={locked ? 'lock' : 'lock-open'}
        onClick={() => act('lock')}
        selected={locked}
        tooltip={`${locked ? 'Unlock' : 'Lock'} the control panel.`}
      >
        Controls Lock
      </Button>
    </>
  );
};

/** If user is a bad silicon, they can press this button to hack the bot */
const HackButton = (props) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { can_hack, emagged } = data;

  return (
    <Button
      color="danger"
      disabled={!can_hack}
      icon={emagged ? 'bug' : 'lock'}
      onClick={() => act('hack')}
      selected={!emagged}
      tooltip={
        !emagged
          ? 'Unlocks the safety protocols.'
          : 'Resets the bot operating system.'
      }
    >
      {emagged ? 'Malfunctional' : 'Safety Lock'}
    </Button>
  );
};

/** Displays the bot's standard settings: Power, patrol, etc. */
const SettingsDisplay = (props) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { settings } = data;
  const {
    airplane_mode,
    patrol_station,
    power,
    maintenance_lock,
    allow_possession,
    possession_enabled,
  } = settings;

  return (
    <LabeledControls>
      <LabeledControls.Item label="Power">
        <Tooltip content={`Powers ${power ? 'off' : 'on'} the bot.`}>
          <Icon
            size={2}
            name="power-off"
            color={power ? 'good' : 'gray'}
            onClick={() => act('power')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Airplane Mode">
        <Tooltip
          content={`${
            !airplane_mode ? 'Disables' : 'Enables'
          } remote access via console.`}
        >
          <Icon
            size={2}
            name="plane"
            color={airplane_mode ? 'yellow' : 'gray'}
            onClick={() => act('airplane')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Patrol Station">
        <Tooltip
          content={`${
            patrol_station ? 'Disables' : 'Enables'
          } automatic station patrol.`}
        >
          <Icon
            size={2}
            name="map-signs"
            color={patrol_station ? 'good' : 'gray'}
            onClick={() => act('patrol')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Maintenance Lock">
        <Tooltip
          content={
            maintenance_lock
              ? 'Opens the maintenance hatch for repairs.'
              : 'Closes the maintenance hatch.'
          }
        >
          <Icon
            size={2}
            name="toolbox"
            color={maintenance_lock ? 'yellow' : 'gray'}
            onClick={() => act('maintenance')}
          />
        </Tooltip>
      </LabeledControls.Item>
      {!!allow_possession && (
        <LabeledControls.Item label="Personality">
          <Tooltip
            content={
              possession_enabled
                ? 'Resets personality to factory default.'
                : 'Enables download of a unique personality.'
            }
          >
            <Icon
              size={2}
              name="robot"
              color={possession_enabled ? 'good' : 'gray'}
              onClick={() => act('toggle_personality')}
            />
          </Tooltip>
        </LabeledControls.Item>
      )}
    </LabeledControls>
  );
};

/** Iterates over custom controls.
 * Calls the helper to identify which button to use.
 */
const ControlsDisplay = (props) => {
  const { data } = useBackend<SimpleBotContext>();
  const { custom_controls } = data;

  return (
    <LabeledControls wrap>
      {Object.entries(custom_controls).map((control) => {
        return (
          <LabeledControls.Item
            pb={2}
            key={control[0]}
            label={capitalizeAll(control[0].replace('_', ' '))}
          >
            <ControlHelper control={control} />
          </LabeledControls.Item>
        );
      })}
    </LabeledControls>
  );
};

/** Helper function which identifies which button to create.
 * Might need some fine tuning if you are using more advanced controls.
 */
const ControlHelper = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;
  if (control[0] === 'sync_tech') {
    /** Control is for sync - this is medbot specific */
    return <MedbotSync />;
  } else if (control[0] === 'heal_threshold') {
    /** Control is a threshold - this is medbot specific */
    return <MedbotThreshold control={control} />;
  } else if (control[0] === 'tile_stack') {
    return <FloorbotTiles control={control} />;
  } else if (control[0] === 'line_mode') {
    return <FloorbotLine control={control} />;
  } else {
    /** Control is a boolean of some type */
    return (
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'toggle-on' : 'toggle-off'}
        size={2}
        onClick={() => act(control[0])}
      />
    );
  }
};

/** Small button to sync medbots with research. */
const MedbotSync = (props) => {
  const { act } = useBackend<SimpleBotContext>();

  return (
    <Tooltip
      content={multiline`Synchronize surgical data with research network.
       Improves Tending Efficiency.`}
    >
      <Icon
        color="purple"
        name="cloud-download-alt"
        size={2}
        onClick={() => act('sync_tech')}
      />
    </Tooltip>
  );
};

/** Slider button for medbot healing thresholds */
const MedbotThreshold = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Adjusts the sensitivity for damage treatment.">
      <Slider
        minValue={5}
        maxValue={75}
        ranges={{
          good: [-Infinity, 15],
          average: [15, 55],
          bad: [55, Infinity],
        }}
        step={5}
        unit="%"
        value={control[1]}
        onChange={(_, value) => act(control[0], { threshold: value })}
      />
    </Tooltip>
  );
};

/** Tile stacks for floorbots - shows number and eject button */
const FloorbotTiles = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Button
      disabled={!control[1]}
      icon={control[1] ? 'eject' : ''}
      onClick={() => act('eject_tiles')}
      tooltip="Number of floor tiles contained in the bot."
    >
      {control[1] ? `${control[1]}` : 'Empty'}
    </Button>
  );
};

/** Direction indicator for floorbot when line mode is chosen. */
const FloorbotLine = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Enables straight line tiling mode.">
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'compass' : 'toggle-off'}
        onClick={() => act('line_mode')}
        size={!control[1] ? 2 : 1.5}
      >
        {' '}
        {control[1] ? control[1].toString().charAt(0).toUpperCase() : ''}
      </Icon>
    </Tooltip>
  );
};
