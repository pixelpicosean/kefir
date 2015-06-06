const {createStream, createProperty} = require('../patterns/one-source');

const mixin = {

  _init({wait}) {
    this._wait = Math.max(0, wait);
    this._buff = [];
    this._lastTimer = null;
    this._$shiftBuff = () => this._emitValue(this._buff.shift());
  },

  _free() {
    this._buff = null;
    this._lastTimer = null;
    this._$shiftBuff = null;
  },

  _handleValue(x) {
    if (this._activating) {
      this._emitValue(x);
    } else {
      this._buff.push(x);
      this._lastTimer = setTimeout(this._$shiftBuff, this._wait);
    }
  },

  _handleEnd() {
    if (this._activating) {
      this._emitEnd();
    } else {
      if (this._lastTimer) {
        let cb = this._lastTimer.callback;
        this._lastTimer.callback = () => {
          cb();
          this._emitEnd();
        }
      }
      else {
        setTimeout(() => this._emitEnd(), this._wait);
      }
    }
  }

};

const S = createStream('delay', mixin);
const P = createProperty('delay', mixin);

module.exports = function delay(obs, wait) {
  return new (obs._ofSameType(S, P))(obs, {wait});
};
