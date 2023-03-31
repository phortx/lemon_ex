defmodule LemonEx.Webhooks.EventParserTest do
  use Support.ConnCase

  alias LemonEx.Webhooks.EventParser

  @endpoint "/webhook/lemonsqueezy"

  describe "parse/1" do
    test "returns an error if no x-signature exists" do
      conn = conn(:post, @endpoint)
      assert {:error, 400, "X-Signature missing."} = EventParser.parse(conn)
    end

    test "returns an error if the signature doesn't match the payload hash" do
      raw_payload = load_json(:event)

      conn =
        conn(:post, @endpoint, raw_payload)
        |> put_req_header("x-signature", "foobar")

      assert {:error, 400, "Signature and Payload Hash unequal."} = EventParser.parse(conn)
    end

    test "returns an event if successful" do
      raw_payload = load_json(:event)
      signature = gen_signature(raw_payload)

      conn =
        conn(:post, @endpoint, raw_payload)
        |> put_req_header("x-signature", signature)

      assert {:ok, event} = EventParser.parse(conn)

      assert event.name == "order_created"
      assert event.meta["custom_data"]["customer_id"] == 25

      assert %LemonEx.Orders.Order{} = event.data
      assert event.data.identifier == "636f855c-1fb9-4c07-b75c-3a10afef010a"
    end
  end
end