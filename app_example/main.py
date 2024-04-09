import os
import pathlib
import fastapi
import pydantic
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline


def device() -> str:
    if torch.cuda.is_available():
        return 'cuda'

    return 'mps' if torch.backends.mps.is_available() else 'cpu'


# where our our models saved, this is an environment variable so it can be
# passed in at runtime vs hardcoded -- eg it may change in a container vs
# locally.
model_root = pathlib.Path(os.environ['MODEL_ROOT_PATH'])
assert model_root.exists()

# model itself is gonna be relative to the root path, this is likely not gonna be
# dynamic, but hardcoded
model_name = os.environ['MODEL_VERSION']
model_path = model_root / model_name
assert model_path.exists()

# set this up once at the top level of the file so it's available
# only impact boot time vs every request.
tokenizer = AutoTokenizer.from_pretrained(str(model_path))
model = AutoModelForCausalLM.from_pretrained(str(model_path)).to(device())
pipe = pipeline('text-generation', model=model, tokenizer=tokenizer)

app = fastapi.FastAPI()

class PromptRequest(pydantic.BaseModel):
    prompt: str

class PrompResponse(pydantic.BaseModel):
    generated_text: str

@app.get('/health')
def health() -> str:
    return 'ok'

@app.post('/')
def prompt(prompt: PromptRequest) -> PrompResponse:
    """
    Pretend this does actual stuff, and is like a real app
    """
    result = pipe(prompt.prompt, max_length=100)[0]
    return PrompResponse(generated_text=result['generated_text'])
