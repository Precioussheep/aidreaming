import pathlib
import time
import typing

LOG_DIRECTORY: typing.Final[str] = "/app/outputs/"


def check_log_directory(log_dir: str | pathlib.Path = LOG_DIRECTORY, stale_time: float | int = 3600) -> None:
    """
    For a given globally defined directory, determine if the files have
    been modified in the last hour.

    :param log_dir: The directory to check files in
    :param stale_time: The delta period between now and when the file was last modified to consider a file "stale"

    :return None:
    """
    # convert to pathlib for use of glob etc
    log_dir = pathlib.Path(log_dir)

    benchmark_time = time.time()

    # get all _files_ (recursively) in a directory that are older than the stale_time
    # note pathlib.Path().lstat().st_mtime is equiv to os.path.getmtime()
    #   (which itself is a wrapper around os.stat, which is what the pathlib lstat call is)
    modified_files = [
        f for f in log_dir.rglob("*") if f.is_file() and benchmark_time - f.lstat().st_mtime > stale_time
    ]

    if not modified_files:
        # Here I want a kubectl command to delete this deployment and service
        print("No changes in the last hour")


# when calling as cli, rather than importing as a module
if __name__ == "__main__":
    while True:
        check_log_directory()
        time.sleep(60)  # Sleep for 1 minute before checking again
