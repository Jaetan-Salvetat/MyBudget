"""EuroBERT passe-t-il la chaine d'export du projet : trace ONNX, axes
dynamiques, quantification int8, inference onnxruntime ?"""
import sys, tempfile
from pathlib import Path

import numpy as np
import onnx
import onnxruntime as ort
import torch
import torch.nn as nn
from onnxruntime.quantization import QuantType, quantize_dynamic
from transformers import AutoModel, AutoTokenizer

from training.train import mean_pool

NUM_CATEGORIES = 80


class Wrapper(nn.Module):
    def __init__(self, backbone, hidden):
        super().__init__()
        self.backbone = backbone
        self.type_head = nn.Linear(hidden, 2)
        self.category_head = nn.Linear(hidden, NUM_CATEGORIES)
        self.recurrence_head = nn.Linear(hidden, 2)

    def forward(self, input_ids, attention_mask):
        hidden = self.backbone(input_ids=input_ids, attention_mask=attention_mask).last_hidden_state
        pooled = mean_pool(hidden, attention_mask)
        return self.type_head(pooled), self.category_head(pooled), self.recurrence_head(pooled)


for repo in sys.argv[1:]:
    out = Path(tempfile.mkdtemp())
    try:
        tok = AutoTokenizer.from_pretrained(repo)
        backbone = AutoModel.from_pretrained(repo, dtype=torch.float32).eval()
        model = Wrapper(backbone, backbone.config.hidden_size).eval()
        dummy = tok("test", return_tensors="pt", truncation=True, padding="max_length", max_length=16)

        torch.onnx.export(
            model, (dummy["input_ids"], dummy["attention_mask"]), str(out / "raw.onnx"),
            input_names=["input_ids", "attention_mask"],
            output_names=["type_logits", "category_logits", "recurrence_logits"],
            dynamic_axes={"input_ids": {0: "batch", 1: "sequence"},
                          "attention_mask": {0: "batch", 1: "sequence"}},
            opset_version=17, do_constant_folding=True)
        onnx.checker.check_model(onnx.load(str(out / "raw.onnx")))
        quantize_dynamic(str(out / "raw.onnx"), str(out / "int8.onnx"), weight_type=QuantType.QInt8)

        session = ort.InferenceSession(str(out / "int8.onnx"))
        enc = tok(["carrefour city la rochelle", "abonnement netflix"], return_tensors="np", padding=True)
        logits = session.run(None, {"input_ids": enc["input_ids"].astype(np.int64),
                                    "attention_mask": enc["attention_mask"].astype(np.int64)})
        size = (out / "int8.onnx").stat().st_size / 1e6
        print(f"{repo:30s} OK — int8 {size:.0f} Mo, sortie {[tuple(l.shape) for l in logits]}", flush=True)
    except Exception as e:
        print(f"{repo:30s} ECHEC {type(e).__name__}: {str(e)[:160]}", flush=True)
