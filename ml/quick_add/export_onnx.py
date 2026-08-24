import torch
import torch.nn as nn
import onnx
from onnxruntime.quantization import QuantType, quantize_dynamic
from pathlib import Path
from transformers import AutoTokenizer

from train import BudgetClassifier, BudgetClassifierConfig, mean_pool

MODEL_PATH = Path(__file__).parent / "output" / "best"
ONNX_RAW = Path(__file__).parent / "output" / "model_raw.onnx"
ONNX_MERGED = Path(__file__).parent / "output" / "model_merged.onnx"
ONNX_FINAL = Path(__file__).parent / "output" / "model.onnx"

# Traced short so nothing bakes a padded length into the graph : the sequence
# axis stays symbolic and the app pads to the smallest bucket that fits.
SEQUENCE_TRACE_LENGTH = 16


class OnnxFullModel(nn.Module):
    """Wraps the full multi-head model for ONNX export (returns 3 logit tensors)."""

    def __init__(self, model: BudgetClassifier):
        super().__init__()
        self.backbone = model.backbone
        self.type_head = model.type_head
        self.category_head = model.category_head
        self.recurrence_head = model.recurrence_head

    def forward(self, input_ids: torch.LongTensor, attention_mask: torch.LongTensor):
        outputs = self.backbone(input_ids=input_ids, attention_mask=attention_mask)
        pooled = mean_pool(outputs.last_hidden_state, attention_mask)
        return (
            self.type_head(pooled),
            self.category_head(pooled),
            self.recurrence_head(pooled),
        )


def export_full_model() -> None:
    """Export the full multi-head model as a single ONNX file with 3 outputs."""
    config = BudgetClassifierConfig.from_pretrained(str(MODEL_PATH))
    model = BudgetClassifier.from_pretrained(str(MODEL_PATH), config=config)
    model.eval()

    tokenizer = AutoTokenizer.from_pretrained(str(MODEL_PATH))
    dummy = tokenizer("test", return_tensors="pt", truncation=True, padding="max_length", max_length=SEQUENCE_TRACE_LENGTH)

    wrapper = OnnxFullModel(model)

    torch.onnx.export(
        wrapper,
        (dummy["input_ids"], dummy["attention_mask"]),
        str(ONNX_RAW),
        input_names=["input_ids", "attention_mask"],
        output_names=["type_logits", "category_logits", "recurrence_logits"],
        dynamic_axes={
            "input_ids": {0: "batch", 1: "sequence"},
            "attention_mask": {0: "batch", 1: "sequence"},
            "type_logits": {0: "batch"},
            "category_logits": {0: "batch"},
            "recurrence_logits": {0: "batch"},
        },
        opset_version=17,
        dynamo=False,
    )

    raw_model = onnx.load(str(ONNX_RAW), load_external_data=True)
    raw_model.opset_import[0].version = 18
    onnx.save(raw_model, str(ONNX_MERGED), save_as_external_data=False)
    print(f"Merged: {ONNX_MERGED} ({ONNX_MERGED.stat().st_size / 1024 / 1024:.1f} MB)")

    ONNX_RAW.unlink(missing_ok=True)
    for p in ONNX_RAW.parent.glob("model_raw.onnx.*"):
        p.unlink(missing_ok=True)

    quantize_dynamic(str(ONNX_MERGED), str(ONNX_FINAL), weight_type=QuantType.QInt8)
    print(f"Quantized: {ONNX_FINAL} ({ONNX_FINAL.stat().st_size / 1024 / 1024:.1f} MB)")

    ONNX_MERGED.unlink(missing_ok=True)


def main() -> None:
    export_full_model()


if __name__ == "__main__":
    main()
