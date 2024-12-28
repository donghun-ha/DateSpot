from fastapi import HTTPException, APIRouter,Query
from fastapi.responses import StreamingResponse
import user
from botocore.exceptions import ClientError
from urllib.parse import unquote

router = APIRouter()


@router.get('/restaurant_select_all')
async def select():
    redis = user.get_redis_connection()
    try:
        conn = user.connect()
        curs = conn.cursor()
        sql = "select * from restaurant"
        curs.execute(sql)
        data = curs.fetchall()
        print(data)
        return {"result" : data}
    except Exception as e :
        print("restaurant.py select Error")
        return {"restaurant.py select Error" : e}
    
# 디테일 페이지로 이동할때 클릭한 restaurant 정보 쿼리
@router.get('/go_detail')
async def get_booked_rating(name: str):
    conn = user.connect()
    curs = conn.cursor()

    sql = "SELECT * FROM restaurant WHERE name = %s"
    curs.execute(sql, (name,))
    rows = curs.fetchall()
    conn.close()

    if not rows:
        raise HTTPException(status_code=404, detail="Not Found")
    
    # 데이터를 매핑하여 반환 // SwiftUI에 맞는 형태
    results = [
        {
            "name": row[0],
            "address": row[1],
            "lat": row[2],
            "lng": row[3],
            "parking": row[4],
            "operatingHour": row[5],
            "closedDays": row[6],
            "contactInfo": row[7],
            "breakTime": row[8],  # 기존 description -> breakTime
            "lastOrder": row[9]   # 기존 closingTime -> lastOrder
        }
        for row in rows
    ]
    return {"results": results}

import unicodedata
from fastapi import FastAPI, HTTPException
from urllib.parse import unquote

@router.get("/images")
async def get_images(name: str):
    """
    특정 이름에 해당하는 이미지를 S3에서 가져와 리스트로 반환
    """
    s3_client = user.create_s3_client()  # S3 클라이언트 생성

    try:
        # URL 디코딩 및 Unicode 정규화
        decoded_name = unquote(name).strip()
        normalized_name = unicodedata.normalize("NFC", decoded_name)
        print(f"Decoded name: {decoded_name}")
        print(f"Normalized name: {normalized_name}")

        # Prefix 생성
        prefix = f"맛집/{normalized_name}_"
        print(f"Using Prefix: {prefix}")

        # S3에서 파일 검색
        response = s3_client.list_objects_v2(Bucket=user.BUCKET_NAME, Prefix="맛집/")
        all_keys = [content["Key"] for content in response.get("Contents", [])]
        print(f"All S3 Keys: {all_keys}")

        if "Contents" not in response or not response["Contents"]:
            print("No files found in the bucket")
            raise HTTPException(status_code=404, detail="No images found")

        # 검색된 키에서 이름 필터링
        filtered_keys = [
            key for key in all_keys if f"{normalized_name}_" in key
        ]

        print(f"Filtered keys: {filtered_keys}")

        if not filtered_keys:
            print(f"No images found for: {normalized_name}")
            raise HTTPException(status_code=404, detail="No images found")

        return {"images": filtered_keys}

    except Exception as e:
        print(f"Error while fetching images: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching images: {str(e)}")



@router.get("/image")
async def stream_image(file_key: str):
    """
    S3에서 단일 이미지 파일 스트리밍
    """
    s3_client = user.create_s3_client()
    try:
        # 보이지 않는 문자 제거
        cleaned_key = remove_invisible_characters(file_key)
        print(f"Original key: {file_key}")
        print(f"Cleaned key: {cleaned_key}")

        # S3 객체 가져오기
        s3_object = s3_client.get_object(Bucket=user.BUCKET_NAME, Key=cleaned_key)
        return StreamingResponse(
            content=s3_object["Body"],
            media_type="image/jpeg"
        )
    except s3_client.exceptions.NoSuchKey:
        print(f"NoSuchKey error for key: {file_key}")
        raise HTTPException(status_code=404, detail="File not found in S3")
    except Exception as e:
        print(f"Error while streaming image: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

def remove_invisible_characters(input_str: str) -> str:
    # 모든 비표시 가능 문자를 제거 (공백, 제어 문자 포함)
    return ''.join(ch for ch in input_str if ch.isprintable())
