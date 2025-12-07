#!/bin/bash

# Test script to send sample telemetry data to ObserveX
# This demonstrates how to send traces to the OpenTelemetry Collector

OTEL_ENDPOINT="${OTEL_ENDPOINT:-http://localhost:4318}"

echo "======================================"
echo "  ObserveX Telemetry Test Script"
echo "======================================"
echo ""
echo "Sending test data to: $OTEL_ENDPOINT"
echo ""

# Check if OTEL collector is reachable
if ! curl -sf "$OTEL_ENDPOINT/v1/traces" -o /dev/null -X POST -H "Content-Type: application/json" -d '{"resourceSpans":[]}'; then
    echo "❌ Error: Cannot reach OpenTelemetry Collector at $OTEL_ENDPOINT"
    echo "Make sure ObserveX is running (docker compose up -d)"
    exit 1
fi

echo "✅ OpenTelemetry Collector is reachable"
echo ""

# Function to generate a random trace ID
generate_trace_id() {
    openssl rand -hex 16
}

# Function to generate a random span ID
generate_span_id() {
    openssl rand -hex 8
}

# Send a sample trace
TRACE_ID=$(generate_trace_id)
SPAN_ID=$(generate_span_id)
TIMESTAMP_NANOS=$(date +%s%N)

echo "📤 Sending sample trace..."
echo "Trace ID: $TRACE_ID"
echo "Span ID: $SPAN_ID"

TRACE_DATA=$(cat <<EOF
{
  "resourceSpans": [{
    "resource": {
      "attributes": [{
        "key": "service.name",
        "value": {"stringValue": "test-service"}
      }, {
        "key": "service.version",
        "value": {"stringValue": "1.0.0"}
      }]
    },
    "scopeSpans": [{
      "scope": {
        "name": "test-instrumentation"
      },
      "spans": [{
        "traceId": "$TRACE_ID",
        "spanId": "$SPAN_ID",
        "name": "test-operation",
        "kind": 1,
        "startTimeUnixNano": "$TIMESTAMP_NANOS",
        "endTimeUnixNano": "$((TIMESTAMP_NANOS + 1000000000))",
        "attributes": [{
          "key": "http.method",
          "value": {"stringValue": "GET"}
        }, {
          "key": "http.url",
          "value": {"stringValue": "http://example.com/api/test"}
        }, {
          "key": "http.status_code",
          "value": {"intValue": "200"}
        }],
        "status": {}
      }]
    }]
  }]
}
EOF
)

if curl -sf "$OTEL_ENDPOINT/v1/traces" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$TRACE_DATA" > /dev/null; then
    echo "✅ Trace sent successfully!"
else
    echo "❌ Failed to send trace"
    exit 1
fi

echo ""
echo "======================================"
echo "  Test Data Sent Successfully!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Open Grafana: http://localhost:3000"
echo "2. Go to Explore"
echo "3. Select 'Tempo' as datasource"
echo "4. Search for trace ID: $TRACE_ID"
echo ""
echo "Or check Tempo directly:"
echo "curl http://localhost:3200/api/traces/$TRACE_ID"
echo ""
