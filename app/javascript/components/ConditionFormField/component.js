import get from 'lodash/get';
import queryString from 'query-string';
import React from 'react';
import PropTypes from 'prop-types';
import { inject, observer } from 'mobx-react';

import ConditionValueField from '../ConditionValueField/component';
import FormSelect from '../FormSelect/component';

/** Return true if the given op is an available option. */
function opIsValid(op, operatorOptions) {
  return (operatorOptions || []).some(({ id }) => op === id);
}

@inject('conditionSetStore')
@observer
class ConditionFormField extends React.Component {
  static propTypes = {
    conditionSetStore: PropTypes.object,
    condition: PropTypes.object,
    index: PropTypes.number,
  };

  handleChangeRefQing = (leftQingId) => {
    const { condition } = this.props;
    condition.leftQingId = leftQingId;

    this.getFieldData(leftQingId);
  }

  handleChangeOp = (opValue) => {
    const { condition } = this.props;
    condition.op = opValue;
  }

  /**
   * Update the value in the store.
   * If levelName is provided, will update the cascading select 'level' value map.
   */
  handleChangeValue = (value, levelName) => {
    const { condition } = this.props;

    if (levelName !== undefined) {
      const level = condition.levels.find(({ name }) => name === levelName);

      if (!level) {
        console.error('Failed to find level with name:', levelName);
      } else {
        level.selected = value;
      }
    } else {
      condition.value = value;
    }
  }

  getFieldData = async (leftQingId) => {
    const { condition } = this.props;

    ELMO.app.loading(true);
    const url = this.buildUrl(leftQingId);
    try {
      if (process.env.NODE_ENV === 'test') return;

      // TODO: Decompose magical `response` before setting state.
      const response = await $.ajax(url);

      // Need to put this before we set state because setting state may trigger a new one.
      ELMO.app.loading(false);

      const newCondition = {
        ...response,
        // We set option node ID to null since the new leftQing may have a new option set.
        optionNodeId: null,
        // Prefer the existing value and op if they've been set locally.
        value: condition.value || response.value,
        op: condition.op || response.op,
      };

      // Default to the first op if the current one is invalid.
      if (!opIsValid(newCondition.op, newCondition.operatorOptions)) {
        newCondition.op = get(newCondition, 'operatorOptions[0].id') || null;
      }

      Object.assign(condition, newCondition);
    } catch (error) {
      ELMO.app.loading(false);
      console.error('Failed to getFieldData:', error);
    }
  }

  buildUrl = (leftQingId) => {
    const { conditionSetStore: { formId, conditionableId, conditionableType }, condition: { id } } = this.props;
    const params = {
      condition_id: id || '',
      left_qing_id: leftQingId,
      form_id: formId,
      conditionable_id: conditionableId || undefined,
      conditionable_type: conditionableId ? conditionableType : undefined,
    };
    const url = ELMO.app.url_builder.build('form-items', 'condition-form');
    return `${url}?${queryString.stringify(params)}`;
  }

  formatRefQingOptions = (leftQingOptions) => {
    return leftQingOptions.map((o) => {
      return { id: o.id, name: `${o.fullDottedRank}. ${o.code}`, key: o.id };
    });
  }

  handleRemoveClick = () => {
    const { condition } = this.props;
    condition.remove = true;
  }

  buildValueProps = (namePrefix, idPrefix) => {
    const { condition: { optionSetId, optionNodeId, value, levels, updateLevels } } = this.props;

    if (optionSetId) {
      return {
        type: 'cascading_select',
        namePrefix,
        for: `${idPrefix}_value`, // Not a mistake; the for is for value; the others are for selects
        id: `${idPrefix}_option_node_ids_`,
        key: `${idPrefix}_option_node_ids_`,
        optionSetId,
        optionNodeId,
        levels,
        updateLevels,
        onChange: this.handleChangeValue,
      };
    }

    return {
      type: 'text',
      name: `${namePrefix}[value]`,
      for: `${idPrefix}_value`,
      id: `${idPrefix}_value`,
      key: `${idPrefix}_value`,
      value: value || '',
      onChange: this.handleChangeValue,
    };
  }

  shouldDestroy = () => {
    const { conditionSetStore: { hide }, condition: { remove } } = this.props;
    return remove || hide;
  }

  render() {
    const {
      conditionSetStore: { namePrefix: rawNamePrefix, refableQings, forceEqualsOp },
      condition: { id, leftQingId, op, operatorOptions },
      index,
    } = this.props;
    const namePrefix = `${rawNamePrefix}[${index}]`;
    const idPrefix = namePrefix.replace(/[[\]]/g, '_');
    const idFieldProps = {
      type: 'hidden',
      name: `${namePrefix}[id]`,
      id: `${idPrefix}_id`,
      key: `${idPrefix}_id`,
      value: id || '',
    };
    const leftQingFieldProps = {
      name: `${namePrefix}[left_qing_id]`,
      key: `${idPrefix}_left_qing_id`,
      value: leftQingId || '',
      options: this.formatRefQingOptions(refableQings),
      prompt: I18n.t('condition.left_qing_prompt'),
      onChange: this.handleChangeRefQing,
    };
    const operatorFieldProps = {
      name: `${namePrefix}[op]`,
      key: `${idPrefix}_op`,
      value: op || '',
      options: operatorOptions,
      includeBlank: false,
      forceEqualsOp,
      onChange: this.handleChangeOp,
    };
    const destroyFieldProps = {
      type: 'hidden',
      name: `${namePrefix}[_destroy]`,
      id: `${idPrefix}__destroy`,
      key: `${idPrefix}__destroy`,
      value: this.shouldDestroy() ? '1' : '0',
    };
    const valueFieldProps = this.buildValueProps(namePrefix, idPrefix);

    return (
      <div
        className="condition-fields"
        style={{ display: this.shouldDestroy() ? 'none' : '' }}
      >
        <input {...idFieldProps} />
        <input {...destroyFieldProps} />
        <FormSelect {...leftQingFieldProps} />
        {forceEqualsOp ? (
          <div className="operator-text">{I18n.t('common.is')}</div>
        ) : (
          <FormSelect {...operatorFieldProps} />
        )}
        <div className="condition-value">
          <ConditionValueField {...valueFieldProps} />
        </div>
        <div className="condition-remove">
          {/* TODO: Improve a11y. */}
          {/* eslint-disable-next-line */}
          <a onClick={this.handleRemoveClick}>
            <i className="fa fa-close" />
          </a>
        </div>
      </div>
    );
  }
}

export default ConditionFormField;
