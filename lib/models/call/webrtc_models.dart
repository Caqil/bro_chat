class WebRTCConfig {
  final List<IceServer> iceServers;
  final int iceCandidatePoolSize;
  final String bundlePolicy;
  final String rtcpMuxPolicy;

  WebRTCConfig({
    required this.iceServers,
    this.iceCandidatePoolSize = 10,
    this.bundlePolicy = 'max-bundle',
    this.rtcpMuxPolicy = 'require',
  });

  factory WebRTCConfig.fromJson(Map<String, dynamic> json) {
    return WebRTCConfig(
      iceServers: (json['ice_servers'] as List? ?? [])
          .map((e) => IceServer.fromJson(e))
          .toList(),
      iceCandidatePoolSize: json['ice_candidate_pool_size'] ?? 10,
      bundlePolicy: json['bundle_policy'] ?? 'max-bundle',
      rtcpMuxPolicy: json['rtcp_mux_policy'] ?? 'require',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ice_servers': iceServers.map((e) => e.toJson()).toList(),
      'ice_candidate_pool_size': iceCandidatePoolSize,
      'bundle_policy': bundlePolicy,
      'rtcp_mux_policy': rtcpMuxPolicy,
    };
  }
}

class IceServer {
  final List<String> urls;
  final String? username;
  final String? credential;

  IceServer({required this.urls, this.username, this.credential});

  factory IceServer.fromJson(Map<String, dynamic> json) {
    return IceServer(
      urls: List<String>.from(json['urls'] ?? []),
      username: json['username'],
      credential: json['credential'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'urls': urls,
      if (username != null) 'username': username,
      if (credential != null) 'credential': credential,
    };
  }
}

class WebRTCOffer {
  final String type;
  final String sdp;

  WebRTCOffer({required this.type, required this.sdp});

  factory WebRTCOffer.fromJson(Map<String, dynamic> json) {
    return WebRTCOffer(type: json['type'] ?? '', sdp: json['sdp'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'sdp': sdp};
  }
}

class WebRTCAnswer {
  final String type;
  final String sdp;

  WebRTCAnswer({required this.type, required this.sdp});

  factory WebRTCAnswer.fromJson(Map<String, dynamic> json) {
    return WebRTCAnswer(type: json['type'] ?? '', sdp: json['sdp'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'sdp': sdp};
  }
}

class IceCandidate {
  final String candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  IceCandidate({required this.candidate, this.sdpMid, this.sdpMLineIndex});

  factory IceCandidate.fromJson(Map<String, dynamic> json) {
    return IceCandidate(
      candidate: json['candidate'] ?? '',
      sdpMid: json['sdpMid'],
      sdpMLineIndex: json['sdpMLineIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
    };
  }
}
