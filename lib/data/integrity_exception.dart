class IntegrityException {
  int _errorCode;

  int _id;

  int get errorCode {
    return this._errorCode;
  }

  String get errorMessage {
    if (this._errorCode == 1) {
      return "Record whose id is ${this._id} has wrong minutes.";
    }
    if (this._errorCode == 2) {
      return "Routine whose id is ${this._id} has wrong minutes.";
    }
    if (this._errorCode == 3) {
      return "Routine whose id is ${this._id} has wrong score.";
    }
    if (this._errorCode == 4) {
      return "Routine whose id is ${this._id} has wrong type.";
    }
    if (this._errorCode == 5) {
      return "Routine whose id is ${this._id} has wrong totalMinutes.";
    }
    if (this._errorCode == 6) {
      return "Routine whose id is ${this._id} has wrong totalScore.";
    }

    return "Unknown error.";
  }

  IntegrityException(this._errorCode, this._id);
}
