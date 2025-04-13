output "producer_function_url" {
  value = google_cloudfunctions_function.event_producer.https_trigger_url
}
