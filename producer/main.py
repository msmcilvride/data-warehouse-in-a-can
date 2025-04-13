import json
import logging
import os
from datetime import datetime, timezone

import functions_framework
from google.cloud import pubsub_v1


@functions_framework.http
def publish_event(request):
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(os.environ["GCP_PROJECT"], os.environ["PUBSUB_TOPIC"])

    dummy_event = {
        "event_type": "dummy_test_event",
        "timestamp": "2025-04-13 02:25:47.104159 UTC",
        "data": {
            "user_id": "user-123",
            "action": "click",
            "platform": "web"
        }
    }

    print("hello")

    publisher.publish(topic_path, json.dumps(dummy_event).encode("utf-8"))
    return "Event published"
