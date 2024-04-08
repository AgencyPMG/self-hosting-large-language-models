# Self Hosting Large Langauge Models

This is some code for a talk at the AI Camp meetups in Dallas in Austin, TX.

## Getting Started

Run `./bin/dev/up` to setup the environment and download the GPT2 model.

Then run `source .venv/bin/activate` to activate the virtual environment.

## Pytorch is Big

That's why there's this bit in `requirements.txt`

```
--extra-index-url https://download.pytorch.org/whl/cpu
```

Which puts torch in CPU only mode, which is fine for this demo. With a GPU
backed instance, you may want to include CUDA.
