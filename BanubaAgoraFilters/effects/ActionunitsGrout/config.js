function Effect() {
	var self = this;

	this.init = function() {
		Api.meshfxMsg("spawn", 0, 0, "groot.bsm2");
		Api.meshfxMsg("spawn", 1, 0, "quad.bsm2");
		Api.showRecordButton();
	};

	this.faceActions = [];
	this.noFaceActions = [];

	this.videoRecordStartActions = [];
	this.videoRecordFinishActions = [];
	this.videoRecordDiscardActions = [];
}

var effect = new Effect();

configure(effect);
