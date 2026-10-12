import sys
import zipfile
from pathlib import Path


def main() -> None:
    root = Path(sys.argv[1])
    output = Path(sys.argv[2])
    files = [
        path
        for path in root.rglob("*")
        if path.is_file() and "_metadata" not in path.parts
    ]

    with zipfile.ZipFile(
        output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9
    ) as archive:
        for path in files:
            archive.write(path, path.relative_to(root).as_posix())


if __name__ == "__main__":
    main()
