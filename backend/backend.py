import os
from pathlib import Path
from dotenv import load_dotenv


def itemize_recipt(receipt):
    # call the gemini api to itemize the picture of the receipt and return a json
    

    #api call to gemini
    # return the json
    pass

def main():
    # Load the .env file next to this module regardless of the current working directory.
    load_dotenv(Path(__file__).with_name(".env"))

    api_key = os.getenv("API_KEY")
    print(f"Your API Key is: {api_key}")


if __name__ == "__main__":
    main()
