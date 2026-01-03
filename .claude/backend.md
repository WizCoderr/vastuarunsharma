# AWS CloudFront CDN Setup for Video Streaming

## Why Use CloudFront CDN?

### Current Problem
Your videos are failing to load from direct S3 URLs because:
- **Pre-signed URL expiration** - S3 pre-signed URLs expire quickly
- **CORS issues** - S3 requires complex CORS configuration
- **Slow loading** - No edge caching, videos load from single region
- **High bandwidth costs** - Direct S3 egress is expensive

### CloudFront Benefits
1. **Global Edge Caching** - Videos cached at 400+ edge locations worldwide
2. **Signed URLs/Cookies** - Secure, configurable expiration (hours/days)
3. **No CORS Issues** - CloudFront handles cross-origin seamlessly
4. **Lower Costs** - CloudFront bandwidth is cheaper than S3 direct
5. **Better Performance** - Adaptive bitrate streaming support
6. **DDoS Protection** - Built-in AWS Shield protection

---

## Step-by-Step Setup Guide

### Step 1: Create CloudFront Key Pair for Signed URLs

1. Go to **AWS Console** → **CloudFront** → **Key Management** → **Public Keys**
2. Click **Create public key**
3. Generate an RSA key pair locally:
   ```bash
   # Generate private key
   openssl genrsa -out cloudfront-private-key.pem 2048

   # Extract public key
   openssl rsa -pubout -in cloudfront-private-key.pem -out cloudfront-public-key.pem
   ```
4. Copy the content of `cloudfront-public-key.pem` and paste it in AWS Console
5. Save the **Key ID** - you'll need it for signing URLs
6. Store `cloudfront-private-key.pem` securely (use AWS Secrets Manager)

### Step 2: Create Key Group

1. Go to **CloudFront** → **Key Management** → **Key Groups**
2. Click **Create key group**
3. Name: `vastu-video-signing-keys`
4. Select the public key you created
5. Click **Create key group**

### Step 3: Create CloudFront Distribution

1. Go to **CloudFront** → **Distributions** → **Create distribution**

2. **Origin Settings:**
   ```
   Origin domain: vastu-media-prod.s3.ap-south-1.amazonaws.com
   Origin path: /vastu-courses/videos (optional, if videos in subfolder)
   Origin access: Origin access control settings (recommended)
   ```

3. **Create Origin Access Control (OAC):**
   - Click **Create control setting**
   - Name: `vastu-s3-oac`
   - Signing behavior: **Sign requests (recommended)**
   - Origin type: **S3**

4. **Default Cache Behavior:**
   ```
   Viewer protocol policy: Redirect HTTP to HTTPS
   Allowed HTTP methods: GET, HEAD
   Restrict viewer access: Yes
   Trusted key groups: Select your key group
   ```

5. **Cache Key and Origin Requests:**
   ```
   Cache policy: CachingOptimized
   Origin request policy: CORS-S3Origin
   Response headers policy: CORS-with-preflight
   ```

6. **Settings:**
   ```
   Price class: Use all edge locations (or select specific regions)
   Alternate domain name (CNAME): cdn.vastuarunsharma.com (optional)
   SSL Certificate: Default CloudFront certificate (or custom)
   ```

7. Click **Create distribution**
8. **Copy the Distribution domain name** (e.g., `d1234abcd.cloudfront.net`)

### Step 4: Update S3 Bucket Policy

After creating the distribution, AWS will show a policy to copy. Update your S3 bucket policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowCloudFrontServicePrincipal",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::vastu-media-prod/*",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DISTRIBUTION_ID"
                }
            }
        }
    ]
}
```

### Step 5: Block Direct S3 Access (Important!)

1. Go to **S3** → Your bucket → **Permissions**
2. **Block public access** - Enable all blocks
3. Remove any existing public bucket policies
4. Only CloudFront should access your S3 bucket now

---

## Backend Implementation

### Node.js/Express Example

```javascript
// Install: npm install @aws-sdk/cloudfront-signer

const { getSignedUrl } = require('@aws-sdk/cloudfront-signer');
const fs = require('fs');

// Configuration
const CLOUDFRONT_DOMAIN = 'd1234abcd.cloudfront.net'; // Your distribution domain
const KEY_PAIR_ID = 'K1234ABCD'; // Your CloudFront key pair ID
const PRIVATE_KEY = fs.readFileSync('./cloudfront-private-key.pem', 'utf8');
// Or use AWS Secrets Manager in production

// Generate signed URL
function generateSignedVideoUrl(videoPath, expirationHours = 4) {
    const url = `https://${CLOUDFRONT_DOMAIN}/${videoPath}`;

    const signedUrl = getSignedUrl({
        url: url,
        keyPairId: KEY_PAIR_ID,
        privateKey: PRIVATE_KEY,
        dateLessThan: new Date(Date.now() + expirationHours * 60 * 60 * 1000).toISOString()
    });

    return signedUrl;
}

// API Endpoint
app.get('/api/stream-url/:lectureId', async (req, res) => {
    try {
        const { lectureId } = req.params;

        // Get video path from database
        const lecture = await Lecture.findById(lectureId);
        if (!lecture) {
            return res.status(404).json({ error: 'Lecture not found' });
        }

        // Video path in S3 (relative to CloudFront origin)
        const videoPath = lecture.videoKey; // e.g., "course-123/lecture-1.mp4"

        // Generate signed URL valid for 4 hours
        const signedUrl = generateSignedVideoUrl(videoPath, 4);

        res.json({
            url: signedUrl,
            expiresIn: 4 * 60 * 60 // seconds
        });
    } catch (error) {
        console.error('Error generating signed URL:', error);
        res.status(500).json({ error: 'Failed to generate stream URL' });
    }
});
```

### Python/FastAPI Example

```python
# Install: pip install boto3 cryptography

from datetime import datetime, timedelta
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.backends import default_backend
import base64
import json

CLOUDFRONT_DOMAIN = "d1234abcd.cloudfront.net"
KEY_PAIR_ID = "K1234ABCD"

# Load private key
with open("cloudfront-private-key.pem", "rb") as key_file:
    PRIVATE_KEY = serialization.load_pem_private_key(
        key_file.read(),
        password=None,
        backend=default_backend()
    )

def generate_signed_url(video_path: str, expiration_hours: int = 4) -> str:
    url = f"https://{CLOUDFRONT_DOMAIN}/{video_path}"
    expires = datetime.utcnow() + timedelta(hours=expiration_hours)
    expires_timestamp = int(expires.timestamp())

    policy = {
        "Statement": [{
            "Resource": url,
            "Condition": {
                "DateLessThan": {"AWS:EpochTime": expires_timestamp}
            }
        }]
    }

    policy_json = json.dumps(policy, separators=(',', ':'))
    policy_b64 = base64.b64encode(policy_json.encode()).decode()
    policy_b64 = policy_b64.replace('+', '-').replace('=', '_').replace('/', '~')

    signature = PRIVATE_KEY.sign(
        policy_json.encode(),
        padding.PKCS1v15(),
        hashes.SHA1()
    )
    signature_b64 = base64.b64encode(signature).decode()
    signature_b64 = signature_b64.replace('+', '-').replace('=', '_').replace('/', '~')

    signed_url = f"{url}?Policy={policy_b64}&Signature={signature_b64}&Key-Pair-Id={KEY_PAIR_ID}"
    return signed_url

# FastAPI endpoint
@app.get("/api/stream-url/{lecture_id}")
async def get_stream_url(lecture_id: str):
    lecture = await get_lecture(lecture_id)
    if not lecture:
        raise HTTPException(status_code=404, detail="Lecture not found")

    signed_url = generate_signed_url(lecture.video_key, expiration_hours=4)

    return {
        "url": signed_url,
        "expiresIn": 4 * 60 * 60
    }
```

### Using AWS SDK (Recommended)

```javascript
// Using AWS SDK v3
const { CloudFrontClient, CreateInvalidationCommand } = require("@aws-sdk/client-cloudfront");
const { getSignedUrl } = require("@aws-sdk/cloudfront-signer");

// For production, use AWS Secrets Manager
const AWS = require('aws-sdk');

async function getPrivateKey() {
    const secretsManager = new AWS.SecretsManager({ region: 'ap-south-1' });
    const secret = await secretsManager.getSecretValue({
        SecretId: 'cloudfront-signing-key'
    }).promise();
    return secret.SecretString;
}

async function generateSignedVideoUrl(videoPath) {
    const privateKey = await getPrivateKey();

    return getSignedUrl({
        url: `https://${process.env.CLOUDFRONT_DOMAIN}/${videoPath}`,
        keyPairId: process.env.CLOUDFRONT_KEY_PAIR_ID,
        privateKey: privateKey,
        dateLessThan: new Date(Date.now() + 4 * 60 * 60 * 1000).toISOString()
    });
}
```

---

## Environment Variables

Add these to your backend `.env`:

```env
# CloudFront Configuration
CLOUDFRONT_DOMAIN=d1234abcd.cloudfront.net
CLOUDFRONT_KEY_PAIR_ID=K1234ABCD
CLOUDFRONT_PRIVATE_KEY_SECRET=cloudfront-signing-key

# AWS Region
AWS_REGION=ap-south-1
```

---

## Mobile App Integration

### No Changes Required!

Your Flutter app already calls the `/api/stream-url/:lectureId` endpoint. The backend change is transparent to the mobile app.

The response format stays the same:
```json
{
    "url": "https://d1234abcd.cloudfront.net/video.mp4?Policy=...&Signature=...&Key-Pair-Id=...",
    "expiresIn": 14400
}
```

### Optional: Increase URL Expiration

Since CloudFront signed URLs are more secure, you can safely increase expiration:
- **Current (S3):** 15-30 minutes
- **Recommended (CloudFront):** 4-8 hours

This reduces API calls and improves user experience when pausing/resuming videos.

---

## Testing

### 1. Test Signed URL Generation

```bash
# Test your API endpoint
curl -X GET "https://api.vastuarunsharma.com/api/stream-url/LECTURE_ID" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 2. Test Video Playback

```bash
# The returned URL should work directly in browser
# Open the signed URL in a browser - video should play
```

### 3. Test Expiration

```bash
# Wait for URL to expire, then try again
# Should return 403 Forbidden
```

---

## Cache Invalidation

When you update a video, invalidate the CloudFront cache:

```javascript
const { CloudFrontClient, CreateInvalidationCommand } = require("@aws-sdk/client-cloudfront");

async function invalidateVideo(videoPath) {
    const client = new CloudFrontClient({ region: "us-east-1" });

    await client.send(new CreateInvalidationCommand({
        DistributionId: "YOUR_DISTRIBUTION_ID",
        InvalidationBatch: {
            CallerReference: Date.now().toString(),
            Paths: {
                Quantity: 1,
                Items: [`/${videoPath}`]
            }
        }
    }));
}
```

---

## Cost Estimation

### CloudFront Pricing (ap-south-1)
- **Data Transfer:** $0.085/GB (first 10TB)
- **HTTP Requests:** $0.0090 per 10,000 requests

### Example Monthly Cost
- 1000 students watching 10 hours/month each
- Average video bitrate: 2 Mbps
- Monthly data: ~9 TB
- **Estimated cost:** ~$765/month

### Compared to Direct S3
- S3 egress: $0.1093/GB
- **Same usage:** ~$983/month
- **Savings:** ~22% + better performance!

---

## Troubleshooting

### Error: Access Denied
- Check S3 bucket policy has CloudFront OAC permission
- Verify distribution is deployed (can take 5-10 mins)
- Check if video path is correct

### Error: Invalid Signature
- Verify private key matches the public key in AWS
- Check KEY_PAIR_ID is correct
- Ensure expiration time is in the future

### Video Not Caching
- Check Cache-Control headers on S3 objects
- Verify cache policy is applied to behavior
- Check if query strings are forwarded (they shouldn't be for caching)

### Slow First Load
- Normal! First request goes to origin (S3)
- Subsequent requests are fast (from edge cache)
- Consider pre-warming popular videos

---

## Security Checklist

- [ ] Private key stored in AWS Secrets Manager (not in code)
- [ ] S3 bucket blocks all public access
- [ ] Only CloudFront can access S3 via OAC
- [ ] Signed URLs have reasonable expiration (4-8 hours)
- [ ] HTTPS enforced (HTTP redirected)
- [ ] Geo-restriction enabled if needed (India only?)
- [ ] AWS WAF enabled for additional protection

---

## Summary

### What You Need to Do:

1. **AWS Console:**
   - Create CloudFront key pair
   - Create CloudFront distribution
   - Update S3 bucket policy
   - Block direct S3 access

2. **Backend Code:**
   - Install CloudFront signer library
   - Update stream URL endpoint to use CloudFront signed URLs
   - Store private key in Secrets Manager

3. **No Mobile App Changes Required!**

### Result:
- Videos load faster globally
- No more expired URL errors
- Better security with signed URLs
- Lower costs at scale
